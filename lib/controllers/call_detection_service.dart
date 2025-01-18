import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

@pragma('vm:entry-point')
void backgroundServiceHandler() async {
  final service = FlutterBackgroundService();
  
  // Initialize service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      initialNotificationTitle: 'Call Detection Service',
      initialNotificationContent: 'Running in background',
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
Future<void> onServiceStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }
  
  await initializeCallDetection();
}

// Add the missing initialization function
Future<void> initializeCallDetection() async {
  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
      
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload == 'alert_screen') {
        // Handle notification tap
      }
    },
  );

  // Request necessary permissions
  await Future.wait([
    Permission.phone.request(),
    Permission.notification.request(),
    PhoneStateBackground.checkPermission(),
  ]);

  // Initialize phone state background handler
  await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
}

@pragma('vm:entry-point')
Future<void> phoneStateBackgroundCallbackHandler(
  PhoneStateBackgroundEvent event,
  String number,
  int duration,
) async {
  final callDetectionService = CallDetectionService();
  await callDetectionService.initializeBackground();

  switch (event) {
    case PhoneStateBackgroundEvent.incomingstart:
    case PhoneStateBackgroundEvent.outgoingstart:
      // Launch app and show alert
      await _launchApp();
      await callDetectionService.handleCall(
        number, 
        isIncoming: event == PhoneStateBackgroundEvent.incomingstart
      );
      break;
    case PhoneStateBackgroundEvent.incomingend:
    case PhoneStateBackgroundEvent.outgoingend:
      await callDetectionService.handleCallEnd();
      break;
    default:
      break;
  }
}

Future<void> _launchApp() async {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const androidDetails = AndroidNotificationDetails(
    'call_detection_channel',
    'Call Detection',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true, // This is crucial for launching on locked screen
    showWhen: true,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);
  
  await notificationsPlugin.show(
    0,
    'Incoming Call',
    'Tap to view caller details',
    notificationDetails,
    payload: 'alert_screen',
  );
}

class CallDetectionService {
  static final CallDetectionService _instance = CallDetectionService._internal();
  final CallerApiService _callerApiService = CallerApiService();
  late Database database;
  bool _isAlertScreenShowing = false;
  Timer? _screenTimer;
  factory CallDetectionService() => _instance;
  CallDetectionService._internal();

  Future<void> initialize(BuildContext context) async {
    await _initPermissions();
    await initializeBackground();
    await _initPhoneStateListener();
    await _initializeNotifications();
    backgroundServiceHandler();
  }
  Future<void> _initializeNotifications() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null) {
          final data = json.decode(payload);
          await _handleNotificationTap(data);
        }
      },
    );
  }
   Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    if (data['type'] == 'call_alert' && !_isAlertScreenShowing) {
      final phoneNumber = data['phoneNumber'];
      final isIncoming = data['isIncoming'];
      
      if (navigatorKey.currentState != null) {
        await Navigator.push(
          navigatorKey.currentState!.context,
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

  Future<void> initializeBackground() async {
    await _initDatabase();
    await _requestPermissions();
  }

  Future<void> _initPermissions() async {
    final permissions = await Future.wait([
      Permission.phone.request(),
      Permission.notification.request(),
    ]);
    
    for (var status in permissions) {
      if (!status.isGranted) {
        log('Warning: Not all permissions granted. Some features may not work.');
      }
    }
  }
   Future<void> _requestPermissions() async {
    await PhoneStateBackground.checkPermission();
    await PhoneStateBackground.requestPermissions();
    
    // Request other necessary permissions
    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    await notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
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
      // Keep screen on
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_TURN_SCREEN_ON);
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SHOW_WHEN_LOCKED);
      
      _screenTimer?.cancel();

      final callerInfo = await _callerApiService.getNumberInfo(phoneNumber);
      
      // Show notification with caller info
      await _showCallerNotification(phoneNumber, isIncoming, callerInfo);
      
      if (callerInfo?.isSpam == true) {
        await _logSpamCall(phoneNumber, isIncoming, callerInfo!);
      }

      // Only show alert screen if app is in foreground
      if (!Platform.isAndroid || await isAppInForeground()) {
        await _showAlertScreen(phoneNumber, isIncoming);
      }
      
      _screenTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
      });
      
    } catch (e) {
      log('Error handling call: $e');
    }
  }
   Future<void> _showCallerNotification(
    String phoneNumber, 
    bool isIncoming, 
    CallerInfo? callerInfo
  ) async {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    
    final androidDetails = AndroidNotificationDetails(
      'call_detection_channel',
      'Call Detection',
      channelDescription: 'Notifications for incoming and outgoing calls',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      showWhen: true,
      category: AndroidNotificationCategory.call,
      styleInformation: BigTextStyleInformation(
        _buildNotificationText(callerInfo, phoneNumber, isIncoming),
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    final payload = json.encode({
      'type': 'call_alert',
      'phoneNumber': phoneNumber,
      'isIncoming': isIncoming,
    });

    await notificationsPlugin.show(
      0,
      _getNotificationTitle(isIncoming),
      _buildNotificationText(callerInfo, phoneNumber, isIncoming),
      notificationDetails,
      payload: payload,
    );
  }

  String _getNotificationTitle(bool isIncoming) {
    return isIncoming ? 'Incoming Call' : 'Outgoing Call';
  }

  String _buildNotificationText(
    CallerInfo? callerInfo, 
    String phoneNumber,
    bool isIncoming,
  ) {
    final buffer = StringBuffer();
    
    if (callerInfo?.name != null) {
      buffer.writeln('Name: ${callerInfo!.name}');
    }
    
    buffer.writeln('Number: $phoneNumber');
    
    if (callerInfo?.provider != null) {
      buffer.writeln('Provider: ${callerInfo!.provider}');
    }
    
    if (callerInfo?.isSpam == true) {
      buffer.writeln('⚠️ Potential spam call');
      if (callerInfo?.spamCount != 0) {
        buffer.writeln('Reported ${callerInfo!.spamCount} times');
      }
    }
    
    buffer.writeln('\nTap to view more details');
    
    return buffer.toString();
  }

  Future<bool> isAppInForeground() async {
    final lifecycleState = await _getAppLifecycleState();
    return lifecycleState == AppLifecycleState.resumed;
  }

  Future<AppLifecycleState> _getAppLifecycleState() async {
    final completer = Completer<AppLifecycleState>();
    
    // Use a timer to ensure we get a value even if no state change occurs
    Timer(const Duration(milliseconds: 100), () {
      if (!completer.isCompleted) {
        completer.complete(WidgetsBinding.instance.lifecycleState ?? 
                         AppLifecycleState.detached);
      }
    });
    
    return completer.future;
  }


   Future<void> handleCallEnd() async {
    _screenTimer?.cancel();
    if (_isAlertScreenShowing && navigatorKey.currentState != null) {
      navigatorKey.currentState!.pop();
      _isAlertScreenShowing = false;
    }
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
  }

 Future<void> _showAlertScreen(String phoneNumber, bool isIncoming) async {
    if (!_isAlertScreenShowing && navigatorKey.currentState != null) {
      _isAlertScreenShowing = true;
      
      try {
        await showDialog(
          context: navigatorKey.currentState!.context,
          barrierDismissible: false,
          useSafeArea: false, // Allow full screen display
          builder: (BuildContext dialogContext) => WillPopScope(
            onWillPop: () async => false,
            child: AlertScreen(
              phoneNumber: phoneNumber,
              callType: isIncoming ? CallType.incoming : CallType.outgoing,
              
            ),
          ),
        );
      } catch (e) {
        log('Error showing alert screen: $e');
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
    log('Error logging spam call: $e');
  }
}

}