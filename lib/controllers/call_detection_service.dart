// services/call_detection_service.dart
import 'dart:developer';

import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:secureconnect/models/caller_info.dart';
import 'package:secureconnect/screens/alert.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'caller_api_service.dart';

enum CallType { incoming, outgoing }

class CallDetectionService {
  static final CallDetectionService _instance = CallDetectionService._internal();
  final CallerApiService _callerApiService = CallerApiService();
  late Database database;
  
  factory CallDetectionService() => _instance;
  CallDetectionService._internal();

  Future<void> initialize(BuildContext context) async {
    await _initDatabase();
    log('phone init');
    
    // Request both phone and phone state permissions
    final phoneStatus = await Permission.phone.request();
    // if (context.mounted){
    //  _showAlertScreen(context, '', true);}
    // print('Phone permissions not granted. Status - Phone: $phoneStatus');
    // final phoneStateStatus = await Permission.phoneState.request();
    
    if (phoneStatus.isGranted ) {
      try {
        PhoneState.stream.listen((event) async {
          // Use a separate BuildContext for navigation
          if (context.mounted) {
            if (event.status == PhoneStateStatus.CALL_INCOMING ||
                event.status == PhoneStateStatus.CALL_STARTED) {
              final phoneNumber = event.number ?? '';
              final isIncoming = event.status == PhoneStateStatus.CALL_INCOMING;
              
              // Get caller info from API
              final callerInfo = await _callerApiService.getNumberInfo(phoneNumber);
              
              if (callerInfo?.isSpam == true) {
                // Log spam call locally
                await _logSpamCall(phoneNumber, isIncoming, callerInfo!);
              }
              
              // Show alert using a separate method to handle navigation
              _showAlertScreen(context, phoneNumber, isIncoming);
            }
          }
        }, onError: (error) {
          print('Phone state stream error: $error');
        });
      } catch (e) {
        print('Error initializing phone state listener: $e');
      }
    } else {
      print('Phone permissions not granted. Status - Phone: $phoneStatus');
    }
  }


  Future<void> _initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'spam_calls.db'),
      onCreate: (db, version) {
        return db.execute(
  'CREATE TABLE spam_calls('
  'id INTEGER PRIMARY KEY AUTOINCREMENT, '
  'phoneNumber TEXT, '
  'timestamp INTEGER, '
  'callType TEXT, '
  'name TEXT, '
  'isSpam INTEGER, '
  'spamCount INTEGER, '
  'provider TEXT, '
  'country TEXT, '
  'numberType TEXT'
  ')',
);;
      },
      version: 1,
    );
  }

Future<void> _logSpamCall(String phoneNumber, bool isIncoming, CallerInfo callerInfo) async {
  final spamCall = SpamCall(
    phoneNumber: phoneNumber,
    timestamp: DateTime.now(),
    callType: isIncoming ? 'incoming' : 'outgoing',
    name: callerInfo.name,
    isSpam: callerInfo.isSpam,
    spamCount: callerInfo.spamCount,
    provider: callerInfo.provider,
    country: callerInfo.country,
    numberType: callerInfo.numberType,
  );

  try {
    await database.insert(
      'spam_calls',
      spamCall.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    print('Error logging spam call: $e');
  }
}

   void _showAlertScreen(BuildContext context, String phoneNumber, bool isIncoming) {
    if (context.mounted) {
      // Use Navigator.of(context) to ensure proper context usage
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AlertScreen(
            phoneNumber: phoneNumber,
            callType: isIncoming ? CallType.incoming : CallType.outgoing,
          ),
        ),
      );
    }
  }
}