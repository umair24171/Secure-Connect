// services/caller_api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:secureconnect/models/caller_info.dart';

class CallerApiService {
  static const String baseUrl = 'https://callerapi.com/api/phone/info/';
   static const String apiKey = '381456b6-68ef-43ef-8701-520204e6f931';
  
  Future<CallerInfo?> getNumberInfo(String phoneNumber) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$phoneNumber'),headers: {'X-Auth': '$apiKey'},);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CallerInfo.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching caller info: $e');
      return null;
    }
  }
}