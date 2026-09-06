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
  // 🔥 Eyecon3 for caller info
  static const String eyeconUrl = 'https://eyecon3.p.rapidapi.com/api/v1';
  static const String eyeconApiKey = '';
  static const String eyeconApiHost = 'eyecon.p.rapidapi.com';
  
  // 🔥 CallerAPI for spam detection
  static const String callerApiUrl = 'https://api.callerapi.com/api/lookup';
  static const String callerApiKey = '';
  
  
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

 /// 🔥 Main method: Get caller info from BOTH APIs and merge
Future<CallerInfo?> getNumberInfo(String phoneNumber) async {
  log('=== Starting dual API lookup for: $phoneNumber ===');
  
  if (!await _checkInternetConnection()) {
    log('No internet connection available');
    return null;
  }

  try {
    // 🔥 Call BOTH APIs in parallel for speed
    final results = await Future.wait([
      _getEyeconInfo(phoneNumber),
      _getCallerApiSpamInfo(phoneNumber),
    ], eagerError: false);

    // 🔥 FIX: Cast the results properly
    final eyeconInfo = results[0] as CallerInfo?;
    final spamInfo = results[1] as Map<String, dynamic>?;

    // 🔥 Merge results
    CallerInfo? mergedInfo = _mergeCallerInfo(eyeconInfo, spamInfo, phoneNumber);
    
    if (mergedInfo != null) {
      log('✅ MERGED INFO: ${mergedInfo.name} | Spam: ${mergedInfo.isSpam} (${mergedInfo.spamCount} reports)');
      
      // Save to Firebase if spam
      if (mergedInfo.isSpam) {
        _saveSpamCallAsync(mergedInfo, phoneNumber, 'incoming');
      }
    }

    return mergedInfo;
  } catch (e, stack) {
    log('❌ Error in dual API lookup: $e');
    log('Stack: $stack');
    return null;
  }
}
  /// 🔥 Get caller info from Eyecon3
 /// 🔥 Get caller info from Eyecon3 - Reduce retries
Future<CallerInfo?> _getEyeconInfo(String phoneNumber) async {
  log('🔍 Fetching Eyecon3 info...');
  
  int attempts = 0;
  const maxAttempts = 2; // 🔥 Reduced from 3 to 2
  
  while (attempts < maxAttempts) {
    try {
      final parsedNumber = _parsePhoneNumber(phoneNumber);
      final countryCode = parsedNumber['code'];
      final number = parsedNumber['number'];
      
      final url = '$eyeconUrl/search?code=$countryCode&number=$number';
      log('Eyecon URL: $url');
      
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'X-RapidAPI-Key': eyeconApiKey,
          'X-RapidAPI-Host': eyeconApiHost,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));
      
      log('Eyecon status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          CallerInfo info = CallerInfo.fromEyeconJson(jsonResponse['data']);
          log('✅ Eyecon: ${info.name}');
          return info;
        }
      } else if (response.statusCode == 429) {
        log('⚠️ Eyecon rate limit - skipping retries');
        return null; // 🔥 Don't retry on rate limit
      } else if (response.statusCode == 403) {
        log('❌ Eyecon auth failed - API key exhausted or invalid');
        return null; // 🔥 Don't retry on auth failure
      }
      
      log('⚠️ Eyecon returned no data');
      return null;
    } catch (e) {
      log('⚠️ Eyecon error (attempt ${attempts + 1}): $e');
      if (attempts + 1 < maxAttempts) {
        await Future.delayed(Duration(seconds: 1));
        attempts++;
        continue;
      }
      return null;
    }
  }
  return null;
}

  /// 🔥 Get spam info from CallerAPI
/// 🔥 Get spam info from CallerAPI - Handle 402 error gracefully
Future<Map<String, dynamic>?> _getCallerApiSpamInfo(String phoneNumber) async {
  log('🚨 Fetching CallerAPI spam info...');
  
  int attempts = 0;
  while (attempts < maxRetries) {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final url = '$callerApiUrl/$cleanNumber?hlr=false';
      log('CallerAPI URL: $url');
      
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'x-auth': callerApiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));
      
      log('CallerAPI status: ${response.statusCode}');
      log('CallerAPI response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          final data = jsonResponse['data'] as Map<String, dynamic>;
          
          bool isSpam = data['is_spam'] == true;
          int spamScore = (data['spam_score'] ?? 0) as int;
          int totalComplaints = (data['total_complaints'] ?? 0) as int;
          String? entityType = data['entity_type'] as String?;
          
          String? category;
          if (data['business_info'] != null) {
            final businessInfo = data['business_info'] as Map<String, dynamic>;
            category = businessInfo['category'] as String?;
          }
          
          log('✅ CallerAPI: Spam=$isSpam, Score=$spamScore, Complaints=$totalComplaints');
          
          return {
            'isSpam': isSpam,
            'spamCount': totalComplaints,
            'spamScore': spamScore,
            'category': category ?? entityType,
            'entityType': entityType,
          };
        } else if (jsonResponse['status'] == 'error') {
          log('⚠️ CallerAPI error: ${jsonResponse['message']}');
          return null;
        }
      } else if (response.statusCode == 402) {
        // 🔥 Out of credits - don't retry, just return null
        log('⚠️ CallerAPI out of credits - spam check disabled');
        return null;
      } else if (response.statusCode == 429) {
        log('CallerAPI rate limit (attempt ${attempts + 1})');
        await Future.delayed(Duration(seconds: math.pow(2, attempts).toInt()));
        attempts++;
        continue;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        log('❌ CallerAPI auth failed - check x-auth key');
        return null;
      }
      
      log('⚠️ CallerAPI returned no spam data');
      return null;
    } catch (e) {
      log('⚠️ CallerAPI error (attempt ${attempts + 1}): $e');
      if (attempts + 1 < maxRetries) {
        await Future.delayed(Duration(seconds: 1));
        attempts++;
        continue;
      }
      return null;
    }
  }
  return null;
}

  /// 🔥 Merge Eyecon caller info + CallerAPI spam info
 CallerInfo? _mergeCallerInfo(
  CallerInfo? eyeconInfo,
  Map<String, dynamic>? spamInfo,
  String phoneNumber
) {
  // If we have eyecon info, use it as base
  if (eyeconInfo != null) {
    // Override spam info from CallerAPI if available
    if (spamInfo != null) {
      return CallerInfo(
        name: eyeconInfo.name,
        isSpam: spamInfo['isSpam'] ?? false,
        spamCount: spamInfo['spamCount'] ?? 0,
        provider: eyeconInfo.provider,
        country: eyeconInfo.country,
        numberType: eyeconInfo.numberType,
        photoUrl: eyeconInfo.photoUrl,
        rating: spamInfo['isSpam'] == true 
            ? (spamInfo['spamScore'] ?? 0).toDouble() / 100 * 5 // Convert score to rating
            : eyeconInfo.rating,
        category: spamInfo['category'] ?? eyeconInfo.category,
        websites: eyeconInfo.websites,
        otherNames: eyeconInfo.otherNames,
      );
    }
    // No spam info, return eyecon as-is
    return eyeconInfo;
  }

  // If only spam info available (no eyecon)
  if (spamInfo != null) {
    return CallerInfo(
      name: phoneNumber,
      isSpam: spamInfo['isSpam'] ?? false,
      spamCount: spamInfo['spamCount'] ?? 0,
      category: spamInfo['category'],
      rating: spamInfo['isSpam'] == true 
          ? (spamInfo['spamScore'] ?? 0).toDouble() / 100 * 5
          : null,
    );
  }

  // No info from either API
  return null;
}

  /// Save spam call to Firebase (async)
  Future<void> _saveSpamCallAsync(
    CallerInfo callerInfo, 
    String phoneNumber, 
    String callType
  ) async {
    Future.microtask(() => addSpamCallToFirebase(callerInfo, phoneNumber, callType));
  }

  /// Add spam call to Firebase
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

      await firestore
          .collection('spam_calls')
          .doc(phoneNumber)
          .set(spamCall.toMap(), SetOptions(merge: true))
          .timeout(Duration(seconds: 5));

      log('✅ Spam call saved: $phoneNumber (Count: ${callerInfo.spamCount})');
    } catch (e, stackTrace) {
      log('Error saving spam call: $e');
      log('Stack trace: $stackTrace');
    }
  }

  /// Get spam call history
  Future<List<SpamCall>> getUserSpamCalls() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('spam_calls')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get()
          .timeout(Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => SpamCall.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      log('Error fetching spam calls: $e');
      return [];
    }
  }

  /// Delete spam call
  Future<bool> deleteSpamCall(String phoneNumber) async {
    try {
      await FirebaseFirestore.instance
          .collection('spam_calls')
          .doc(phoneNumber)
          .delete()
          .timeout(Duration(seconds: 5));
      log('Spam call deleted: $phoneNumber');
      return true;
    } catch (e) {
      log('Error deleting spam call: $e');
      return false;
    }
  }

  /// Parse phone number for Eyecon (country code + number)
  Map<String, String> _parsePhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('0') && cleaned.length > 1) {
      cleaned = cleaned.substring(1);
    }
    
    String countryCode = '92'; // Default Pakistan
    String number = cleaned;
    
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
      
      if (cleaned.startsWith('92')) {
        countryCode = '92';
        number = cleaned.substring(2);
      } else if (cleaned.startsWith('1') && cleaned.length == 11) {
        countryCode = '1';
        number = cleaned.substring(1);
      } else if (cleaned.length > 10) {
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
    
    return {'code': countryCode, 'number': number};
  }

  /// Clean phone number for CallerAPI (E.164 format)
  String _cleanPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    
    if (!cleaned.startsWith('+')) {
      if (cleaned.length == 10) {
        cleaned = '+1$cleaned'; // US
      } else if (cleaned.startsWith('92')) {
        cleaned = '+$cleaned';
      } else if (cleaned.startsWith('1') && cleaned.length == 11) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+$cleaned';
      }
    }
    
    return cleaned;
  }

  void dispose() {
    _client.close();
  }
}
