// services/call_detection_service.dart
import 'dart:developer';

import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:secureconnect/main.dart';
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



  bool _isAlertScreenShowing = false;

  
  // Initialize for background operations (without context)
  Future<void> initializeBackground() async {
    await _initDatabase();
  }

  // Initialize for foreground operations (with context)
   Future<void> initialize(BuildContext context) async {
    await _initDatabase();
    await _initPhoneStateListener();
  }

  Future<void> _initPhoneStateListener() async {
   
    final phoneStatus = await Permission.phone.request();
     print('DEBUG: Current permissions:');
  
  // print('Phone State: $phoneState');
   final notification = await Permission.notification.request();
  log('Notification: $notification');
  log('Phone: $phoneStatus');
    // final phoneStateStatus = await Permission.phoneState.request();
    // _showAlertScreen('', true);
    
    if (phoneStatus.isGranted ) {
      PhoneState.stream.listen((event) async {
        switch (event.status) {
          case PhoneStateStatus.CALL_INCOMING:
            final phoneNumber = event.number ?? '';
            await handleIncomingCall(phoneNumber);
            break;
          case PhoneStateStatus.CALL_ENDED:
          // case PhoneStateStatus.CALL_ENDED:
            // Only dismiss if the call actually ended
            if (_isAlertScreenShowing && navigatorKey.currentState != null) {
              navigatorKey.currentState!.pop();
              _isAlertScreenShowing = false;
            }
            break;
          default:
            break;
        }
      });
    }
  }


  Future<void> handleIncomingCall(String phoneNumber) async {
    try {
      // Get caller info from API
      final callerInfo = await _callerApiService.getNumberInfo(phoneNumber);
      
      if (callerInfo?.isSpam == true) {
        await _logSpamCall(phoneNumber, true, callerInfo!);
      }

      // Show alert using global navigator key
       _showAlertScreen(phoneNumber, true);
    } catch (e) {
      print('Error handling incoming call: $e');
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

    Future<void> _showAlertScreen(String phoneNumber, bool isIncoming) async {
    log('Show alert screen called for number: $phoneNumber', name: 'CallDetection');
    
    try {
       await showDialog(
        context: navigatorKey.currentState!.context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertScreen(
          phoneNumber: phoneNumber,
          callType: isIncoming ? CallType.incoming : CallType.outgoing,
          // onDismiss: () {
          //   _isAlertScreenShowing = false;
          //   Navigator.of(dialogContext).pop();
          // },
        ),
      );
    } catch (e, stackTrace) {
      log(
        'Error showing alert screen',
        error: e,
        stackTrace: stackTrace,
        name: 'CallDetection'
      );
      _isAlertScreenShowing = false;
    }
  }

}