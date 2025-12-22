import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/caller_info.dart';

class CallerApiService {
  // Eyecon RapidAPI endpoint
  static const String baseUrl = 'https://eyecon3.p.rapidapi.com/api/v1';
  static const String apiKey = '3ac06090ddmsh67199c62f193313p11d9e2jsnedbd6beeae61';
  static const String apiHost = 'eyecon.p.rapidapi.com'; // FIXED: Should match baseUrl
  static const int maxRetries = 3;
  final _client = http.Client();

  /// Check if device has active internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        log('No network connectivity');
        return false;
      }
      
      // Quick internet check with timeout
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on TimeoutException {
        log('Internet check timed out');
        return false;
      }
    } catch (e) {
      log('Network check error: $e');
      return false;
    }
  }

  /// Fetch caller information from Eyecon3 RapidAPI
  Future<CallerInfo?> getNumberInfo(String phoneNumber) async {
    log('=== Starting API call for: $phoneNumber ===');
    
    // Check internet first
    if (!await _checkInternetConnection()) {
      log('No internet connection available');
      return null;
    }

    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        // Parse phone number
        final parsedNumber = _parsePhoneNumber(phoneNumber);
        final countryCode = parsedNumber['code'];
        final number = parsedNumber['number'];
        
        log('Parsed - Code: $countryCode, Number: $number');
        
        // Build URL
        final url = '$baseUrl/search?code=$countryCode&number=$number';
        log('API URL: $url');
        
        // Make request with timeout
        final response = await _client.get(
          Uri.parse(url),
          headers: {
            'X-RapidAPI-Key': apiKey,
            'X-RapidAPI-Host': apiHost,
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            log('Request timed out (attempt ${attempts + 1})');
            throw TimeoutException('Request timed out');
          },
        );
        
        log('Response status: ${response.statusCode}');
        log('Response headers: ${response.headers}');
        log('Response body (first 500 chars): ${response.body.substring(0, math.min(500, response.body.length))}');
        
        if (response.statusCode == 200) {
          try {
            final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
            
            // Check if response has expected structure
            if (jsonResponse['status'] != true) {
              log('API returned non-success status: ${jsonResponse['status']}');
              log('Message: ${jsonResponse['message']}');
              return null;
            }

            if (jsonResponse['data'] == null) {
              log('API returned null data');
              return null;
            }

            // Parse response
            CallerInfo info = CallerInfo.fromJson(jsonResponse['data']);
            log('Successfully parsed caller info: ${info.name}');

            // If spam detected, save to Firebase (non-blocking)
            if (info.isSpam) {
              _saveSpamCallAsync(info, phoneNumber, 'incoming');
            }

            return info;
          } catch (e, stack) {
            log('Error parsing API response: $e');
            log('Stack trace: $stack');
            return null;
          }
        } else if (response.statusCode == 429) {
          // Rate limit - exponential backoff
          log('Rate limit hit (attempt ${attempts + 1})');
          await Future.delayed(Duration(seconds: math.pow(2, attempts).toInt()));
          attempts++;
          continue;
        } else if (response.statusCode == 403) {
          log('API authentication failed - check API key');
          return null;
        } else {
          log('API error: ${response.statusCode} - ${response.body}');
          return null;
        }
      } on SocketException catch (e) {
        log('Socket error (attempt ${attempts + 1}): $e');
        if (attempts + 1 < maxRetries) {
          await Future.delayed(Duration(seconds: math.pow(2, attempts).toInt()));
          attempts++;
          continue;
        }
        return null;
      } on TimeoutException catch (e) {
        log('Timeout (attempt ${attempts + 1}): $e');
        if (attempts + 1 < maxRetries) {
          await Future.delayed(Duration(seconds: math.pow(2, attempts).toInt()));
          attempts++;
          continue;
        }
        return null;
      } catch (e, stackTrace) {
        log('Unexpected error (attempt ${attempts + 1}): $e');
        log('Stack trace: $stackTrace');
        if (attempts + 1 < maxRetries) {
          await Future.delayed(Duration(seconds: math.pow(2, attempts).toInt()));
          attempts++;
          continue;
        }
        return null;
      }
    }
    
    log('All retry attempts failed for: $phoneNumber');
    return null;
  }

  /// Save spam call to Firebase (async, won't block UI)
  Future<void> _saveSpamCallAsync(
    CallerInfo callerInfo, 
    String phoneNumber, 
    String callType
  ) async {
    // Run in background, don't await
    Future.microtask(() => addSpamCallToFirebase(callerInfo, phoneNumber, callType));
  }

  /// Add spam call information to Firebase Firestore
  Future<void> addSpamCallToFirebase(
    CallerInfo callerInfo, 
    String phoneNumber, 
    String callType
  ) async {
    if (!callerInfo.isSpam) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        log('User not authenticated, cannot save spam call');
        return;
      }

      // Create SpamCall object
      final spamCall = SpamCall(
        phoneNumber: phoneNumber,
        timestamp: DateTime.now(),
        callType: callType,
        name: callerInfo.name,
        isSpam: true,
        spamCount: callerInfo.spamCount,
        provider: callerInfo.provider,
        country: callerInfo.country,
        numberType: callerInfo.numberType,
        userId: userId,
      );

      // Save to Firestore with timeout
      await firestore
          .collection('spam_calls')
          .doc(phoneNumber)
          .set(spamCall.toMap(), SetOptions(merge: true))
          .timeout(Duration(seconds: 5));

      log('Spam call saved: $phoneNumber (Count: ${callerInfo.spamCount})');
    } catch (e, stackTrace) {
      log('Error saving spam call: $e');
      log('Stack trace: $stackTrace');
    }
  }

  /// Get spam call history for current user
  Future<List<SpamCall>> getUserSpamCalls() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('spam_calls')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100) // Add limit for performance
          .get()
          .timeout(Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => SpamCall.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      log('Error fetching spam calls: $e');
      log('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Delete a spam call record
  Future<bool> deleteSpamCall(String phoneNumber) async {
    try {
      await FirebaseFirestore.instance
          .collection('spam_calls')
          .doc(phoneNumber)
          .delete()
          .timeout(Duration(seconds: 5));
      log('Spam call deleted: $phoneNumber');
      return true;
    } catch (e, stackTrace) {
      log('Error deleting spam call: $e');
      log('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Parse phone number to country code and number
  Map<String, String> _parsePhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Remove leading zero
    if (cleaned.startsWith('0') && cleaned.length > 1) {
      cleaned = cleaned.substring(1);
    }
    
    String countryCode = '92'; // Default Pakistan
    String number = cleaned;
    
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
      
      // Extract country code
      if (cleaned.startsWith('92')) {
        countryCode = '92';
        number = cleaned.substring(2);
      } else if (cleaned.startsWith('1') && cleaned.length == 11) {
        countryCode = '1';
        number = cleaned.substring(1);
      } else if (cleaned.length > 10) {
        // Try to extract country code (1-3 digits)
        final possibleCode = cleaned.substring(0, math.min(3, cleaned.length - 10));
        if (possibleCode.isNotEmpty) {
          countryCode = possibleCode;
          number = cleaned.substring(possibleCode.length);
        }
      }
    } else if (cleaned.startsWith('92') && cleaned.length > 10) {
      countryCode = '92';
      number = cleaned.substring(2);
    } else if (cleaned.startsWith('1') && cleaned.length == 11) {
      countryCode = '1';
      number = cleaned.substring(1);
    }
    
    log('Parsed phone - Code: $countryCode, Number: $number');
    return {'code': countryCode, 'number': number};
  }

  /// Clean up resources
  void dispose() {
    _client.close();
  }
}