import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secureconnect/controllers/caller_api_service.dart';
import 'package:secureconnect/main.dart';
import 'package:secureconnect/models/caller_info.dart';
import 'package:secureconnect/screens/alert.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Global callback for background events
@pragma('vm:entry-point')
Future<void> phoneStateBackgroundCallbackHandler(
  PhoneStateBackgroundEvent event,
  String number,
  int duration,
) async {
  // Initialize services for background handling
  final callDetectionService = CallDetectionService();
  await callDetectionService.initializeBackground();

  switch (event) {
    case PhoneStateBackgroundEvent.incomingstart:
    case PhoneStateBackgroundEvent.outgoingstart:
      await callDetectionService.handleCall(number, 
          isIncoming: event == PhoneStateBackgroundEvent.incomingstart);
      break;
    case PhoneStateBackgroundEvent.incomingend:
    case PhoneStateBackgroundEvent.outgoingend:
      await callDetectionService.handleCallEnd();
      break;
    default:
      print('Call event: ${event.toString()}, number: $number, duration: $duration s');
      break;
  }
}

class CallDetectionService {
  static final CallDetectionService _instance = CallDetectionService._internal();
  final CallerApiService _callerApiService = CallerApiService();
  late Database database;
  bool _isAlertScreenShowing = false;
  
  factory CallDetectionService() => _instance;
  CallDetectionService._internal();

  // Initialize for background operations
  Future<void> initializeBackground() async {
    await _initDatabase();
  }

  // Initialize for foreground operations
  Future<void> initialize(BuildContext context) async {
      // _showAlertScreen('3067128817', true);
    await _initDatabase();
    await _initPermissions();
    await _initPhoneStateListener();

  
    await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
  }

  Future<void> _initPermissions() async {
    final permissions = await Future.wait([
      Permission.phone.request(),
      Permission.notification.request(),
    ]);
    
    for (var status in permissions) {
      if (!status.isGranted) {
        print('Warning: Not all permissions granted. Some features may not work.');
      }
    }
  }

  Future<void> _initPhoneStateListener() async {
    PhoneState.stream.listen((event) async {
      switch (event.status) {
        case PhoneStateStatus.CALL_INCOMING:
          await handleCall(event.number ?? '', isIncoming: true);
          break;
        case PhoneStateStatus.CALL_ENDED:
          await handleCallEnd();
          break;
        default:
          break;
      }
    });
  }

  Future<void> handleCall(String phoneNumber, {required bool isIncoming}) async {
    try {
      // Get caller info from API
      final callerInfo = await _callerApiService.getNumberInfo(phoneNumber);
      
      if (callerInfo?.isSpam == true) {
        await _logSpamCall(phoneNumber, isIncoming, callerInfo!);
      }

      // Show alert using global navigator key
      await _showAlertScreen(phoneNumber, isIncoming);
    } catch (e) {
      print('Error handling call: $e');
    }
  }

  Future<void> handleCallEnd() async {
    if (_isAlertScreenShowing && navigatorKey.currentState != null) {
      navigatorKey.currentState!.pop();
      _isAlertScreenShowing = false;
    }
  }

  Future<void> _showAlertScreen(String phoneNumber, bool isIncoming) async {
    if (!_isAlertScreenShowing && navigatorKey.currentState != null) {
      _isAlertScreenShowing = true;
      try {
        await showDialog(
          context: navigatorKey.currentState!.context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => WillPopScope(
            onWillPop: () async => false,
            child: AlertScreen(
              phoneNumber: phoneNumber,
              callType: isIncoming ? CallType.incoming : CallType.outgoing,
            ),
          ),
        );
      } catch (e) {
        print('Error showing alert screen: $e');
        _isAlertScreenShowing = false;
      }
    }
  }

  Future<void> _initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'spam_calls.db'),
      onCreate: (db, version) {
        return db.execute(
          '''CREATE TABLE spam_calls(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phoneNumber TEXT,
            timestamp INTEGER,
            callType TEXT,
            name TEXT,
            isSpam INTEGER,
            spamCount INTEGER,
            provider TEXT,
            country TEXT,
            numberType TEXT
          )'''
        );
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

}