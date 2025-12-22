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
  // ✅ UPDATED: Eyecon RapidAPI endpoint (Dec 2025)
  static const String baseUrl = 'https://eyecon3.p.rapidapi.com/api/v1';
  static const String apiKey = '3ac06090ddmsh67199c62f193313p11d9e2jsnedbd6beeae61'; // Replace with your RapidAPI key
  static const String apiHost = 'eyecon.p.rapidapi.com'; // ✅ HOST WITHOUT "3"
  static const int maxRetries = 3;
  final _client = http.Client();

  /// Check if device has active internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Double check with an actual internet test
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      log('Network check error: $e');
      return false;
    }
  }

  /// Fetch caller information from Eyecon3 RapidAPI
  Future<CallerInfo?> getNumberInfo(String phoneNumber) async {
    if (!await _checkInternetConnection()) {
      log('No internet connection available');
      return null;
    }

    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        // Parse phone number into country code and number
        final parsedNumber = _parsePhoneNumber(phoneNumber);
        final countryCode = parsedNumber['code'];
        final number = parsedNumber['number'];
        
        // ✅ Eyecon3 endpoint: /search?code={country_code}&number={number}
        final url = '$baseUrl/search?code=$countryCode&number=$number';
        
        log('Attempt ${attempts + 1}: Requesting URL: $url');

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
            throw TimeoutException('Request timed out');
          },
        );
        
        log('Response status: ${response.statusCode}');
        log('Response headers: ${response.headers}');
        log('Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          
          // ✅ Check if response is successful
          if (jsonResponse['status'] != true) {
            log('API returned non-success status: ${jsonResponse['status']}');
            return null;
          }

          // ✅ Parse Eyecon3 response
          CallerInfo info = CallerInfo.fromJson(jsonResponse['data']);

          // If the call is detected as spam, add to Firebase
          if (info.isSpam) {
            await addSpamCallToFirebase(info, phoneNumber, 'incoming');
          }

          return info;
        } else if (response.statusCode == 429) {
          // Rate limit - exponential backoff
          log('Rate limit hit, retrying with backoff...');
          await Future.delayed(Duration(seconds: math.pow(2, attempts).toInt()));
          attempts++;
          continue;
        } else if (response.statusCode == 403) {
          log('Invalid API key or subscription expired');
          return null;
        } else {
          log('API error: ${response.statusCode} - ${response.body}');
          return null;
        }
      } on SocketException catch (e) {
        log('Socket error on attempt ${attempts + 1}: $e');
        if (attempts + 1 < maxRetries) {
          await Future.delayed(Duration(seconds: math.pow(2, attempts).toInt()));
          attempts++;
          continue;
        }
        rethrow;
      } catch (e, stackTrace) {
        log('Error on attempt ${attempts + 1}', error: e, stackTrace: stackTrace);
        if (attempts + 1 < maxRetries) {
          await Future.delayed(Duration(seconds: math.pow(2, attempts).toInt()));
          attempts++;
          continue;
        }
        rethrow;
      }
    }
    
    log('All retry attempts failed');
    return null;
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

      // Create a SpamCall object with current user info
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

      // Save to Firestore with phone number as document ID
      await firestore
          .collection('spam_calls')
          .doc(phoneNumber)
          .set(spamCall.toMap(), SetOptions(merge: true));

      log('Spam call added to Firebase: $phoneNumber (Spam count: ${callerInfo.spamCount})');
    } catch (e, stackTrace) {
      log('Error adding spam call to Firebase', error: e, stackTrace: stackTrace);
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
          .get();

      return snapshot.docs
          .map((doc) => SpamCall.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      log('Error fetching spam calls', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Delete a spam call record
  Future<bool> deleteSpamCall(String phoneNumber) async {
    try {
      await FirebaseFirestore.instance
          .collection('spam_calls')
          .doc(phoneNumber)
          .delete();
      log('Spam call deleted: $phoneNumber');
      return true;
    } catch (e, stackTrace) {
      log('Error deleting spam call', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Parse phone number to country code and number
  Map<String, String> _parsePhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Remove leading zero if present
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    
    // Extract country code
    String countryCode = '92'; // Default Pakistan
    String number = cleaned;
    
    if (cleaned.startsWith('+')) {
      // Has + prefix
      cleaned = cleaned.substring(1);
      
      // Extract country code (1-3 digits)
      if (cleaned.startsWith('92')) {
        countryCode = '92';
        number = cleaned.substring(2);
      } else if (cleaned.startsWith('1')) {
        countryCode = '1';
        number = cleaned.substring(1);
      } else if (cleaned.length > 10) {
        // Try to extract country code
        countryCode = cleaned.substring(0, cleaned.length - 10);
        number = cleaned.substring(cleaned.length - 10);
      }
    } else if (cleaned.startsWith('92')) {
      // Has country code without +
      countryCode = '92';
      number = cleaned.substring(2);
    } else if (cleaned.startsWith('1') && cleaned.length == 11) {
      // US number
      countryCode = '1';
      number = cleaned.substring(1);
    } else {
      // No country code, add default
      number = cleaned;
    }
    
    log('Parsed phone - Code: $countryCode, Number: $number');
    return {'code': countryCode, 'number': number};
  }

  /// Format phone number to E.164 format (for display/storage)
  String _formatToE164(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Remove leading zero if present
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    
    // Add Pakistan country code if not present
    if (!cleaned.startsWith('+')) {
      cleaned = '+92$cleaned';
    }
    
    log('Formatted phone number: $cleaned');
    return cleaned;
  }

  /// Clean up resources
  void dispose() {
    _client.close();
  }
}