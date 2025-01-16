// services/call_detection_service.dart
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
    final status = await Permission.phone.request();
    
    if (status.isGranted) {
      PhoneState.stream.listen((event) async {
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

          _showAlertScreen(
            context, 
            phoneNumber,
            isIncoming,
          );
        }
      });
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertScreen(
          phoneNumber: phoneNumber,
          callType: isIncoming ? CallType.incoming : CallType.outgoing,
        ),
      ),
    );
  }
}