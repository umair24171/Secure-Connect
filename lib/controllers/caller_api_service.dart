import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/caller_info.dart';

class CallerApiService {
  static const String baseUrl = 'https://callerapi.com/api/phone/info/';
  static const String apiKey = '48900582-7283-4082-a219-dddbca82e50b';
  static const int maxRetries = 3;
  final _client = http.Client();

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

  Future<CallerInfo?> getNumberInfo(String phoneNumber) async {
    if (!await _checkInternetConnection()) {
      log('No internet connection available');
      return null;
    }

    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final formattedNumber = _formatToE164(phoneNumber);
        final encodedNumber = Uri.encodeComponent(formattedNumber);
        final url = '$baseUrl$encodedNumber';
        
        log('Attempt ${attempts + 1}: Requesting URL: $url');

        final response = await _client.get(
          Uri.parse(url),
          headers: {
            'X-Auth': apiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
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
          final data = json.decode(response.body);
          return CallerInfo.fromJson(data);
        } else {
          log('API error: ${response.statusCode} - ${response.body}');
          if (response.statusCode == 429) { // Too Many Requests
            await Future.delayed(Duration(seconds: math.pow(2, attempts).toInt()));
            attempts++;
            continue;
          }
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

  String _formatToE164(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    
    if (!cleaned.startsWith('+')) {
      cleaned = '+92$cleaned';
    }
    
    log('Formatted phone number: $cleaned');
    return cleaned;
  }

  void dispose() {
    _client.close();
  }
}