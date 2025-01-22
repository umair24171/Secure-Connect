import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:developer' as developer;
// import 'package:dash_bubble/dash_bubble.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

// service_handler.dart
@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  log('Starting Call Service');
  
  try {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setAutoStartOnBootMode(true);
    }

    PhoneState.stream.listen((event) async {
      if (event.number == null || event.number!.isEmpty) {
        log('Received call event with empty number');
        return;
      }

      final callService = CallService();
      
      try {
        switch (event.status) {
          case PhoneStateStatus.CALL_INCOMING:
            log('Incoming call from: ${event.number}');
            await callService._showOverlay(
              event.number!,
              CallScreenType.incoming,
            );
            break;
            
          case PhoneStateStatus.CALL_STARTED:
            log('Call started with: ${event.number}');
            await callService._showOverlay(
              event.number!,
              CallScreenType.outgoing,
            );
            break;
            
          case PhoneStateStatus.CALL_ENDED:
            log('Call ended');
            await callService._hideOverlay();
            break;
            
          default:
            log('Unhandled phone state: ${event.status}');
            break;
        }
      } catch (e) {
        log('Error handling call state: $e');
      }
    });

  } catch (e) {
    log('Error in onServiceStart: $e');
  }
}


enum CallScreenType { incoming, outgoing, missed }

// Initialize service wrapper function
Future<void> initializeCallService() async {
  await CallService().initialize();
}

// call_service.dart
class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  Future<void> initialize() async {
    try {
      await _requestPermissions();
      await _startBackgroundService();
      _initializeOverlayListener();
    } catch (e) {
      log('Error initializing CallService: $e');
      rethrow;
    }
  }

  void _initializeOverlayListener() {
    FlutterOverlayWindow.overlayListener.listen((event) {
      log("Overlay Event: $event");
    });
  }

  Future<void> _requestPermissions() async {
    final bool overlayStatus = await FlutterOverlayWindow.isPermissionGranted();
    if (!overlayStatus) {
      final bool? granted = await FlutterOverlayWindow.requestPermission();
      if (!granted!) {
        throw Exception('Overlay permission is required');
      }
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts,
      Permission.systemAlertWindow,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      throw Exception('Required permissions not granted');
    }
  }

    Future<void> _showOverlay(String phoneNumber, CallScreenType callType) async {
    developer.log('Showing overlay for number: $phoneNumber', name: 'call_service');
    
    if (await FlutterOverlayWindow.isActive()) {
      developer.log('Overlay already active, updating data', name: 'call_service');
      await _updateOverlayData(phoneNumber, callType);
      return;
    }

    try {
      developer.log('Creating new overlay', name: 'call_service');
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "${callType.toString().split('.').last} Call",
        overlayContent: "Call from $phoneNumber",
        flag: OverlayFlag.focusPointer,
        alignment: OverlayAlignment.topCenter,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: WindowSize.matchParent,
        height: 771,
      );

      developer.log('Overlay created successfully', name: 'call_service');
      await _updateOverlayData(phoneNumber, callType);

    } catch (e, stack) {
      developer.log(
        'Error showing overlay',
        name: 'call_service',
        error: e,
        stackTrace: stack
      );
      rethrow;
    }
  }

   Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onServiceStart,
        autoStart: true,
        isForegroundMode: true,
        initialNotificationTitle: 'Call Protection Active',
        initialNotificationContent: 'Monitoring incoming calls',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onServiceStart,
        onBackground: _onIosBackground,
      ),
    );
  }
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }

 Future<void> _updateOverlayData(String phoneNumber, CallScreenType callType) async {
    try {
      final data = {
        'phoneNumber': phoneNumber,
        'callType': callType.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      developer.log('Updating overlay with data: $data', name: 'call_service');
      await FlutterOverlayWindow.shareData(jsonEncode(data));
      developer.log('Overlay data updated successfully', name: 'call_service');
    } catch (e, stack) {
      developer.log(
        'Error updating overlay data',
        name: 'call_service',
        error: e,
        stackTrace: stack
      );
    }
  }

  Future<void> _hideOverlay() async {
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      log('Error hiding overlay: $e');
    }
  }
}

// class CallService {
//   static final CallService _instance = CallService._internal();
//   factory CallService() => _instance;
//   CallService._internal();


//   Future<void> initialize() async {
  

//     try {
//       await _requestPermissions();
//       await _initializeNotifications();
//       // await _initializeBubble();
//       await _startBackgroundService();
     
//     } catch (e) {
//       log('Error initializing CallService: $e');
//       rethrow;
//     }
//   }
  // Future<void> _startBackgroundService() async {
  //   final service = FlutterBackgroundService();

  //   await service.configure(
  //     androidConfiguration: AndroidConfiguration(
  //       onStart: onServiceStart,
  //       autoStart: true,
  //       isForegroundMode: true,
  //       initialNotificationTitle: 'Call Protection Active',
  //       initialNotificationContent: 'Monitoring incoming calls',
  //       foregroundServiceNotificationId: 888,
  //     ),
  //     iosConfiguration: IosConfiguration(
  //       autoStart: true,
  //       onForeground: onServiceStart,
  //       onBackground: _onIosBackground,
  //     ),
  //   );
  // }
//   Future<void> _handleCall(
//   String phoneNumber,
//   CallScreenType callType,
//   CallService callService,
//   ServiceInstance service,
// ) async {
//   try {
//     // Update service notification
//     // if (service is AndroidServiceInstance) {
//     //   _updateServiceNotification(
//     //     service,
//     //     '${callType.toString().split('.').last} Call',
//     //     'Call from $phoneNumber',
//     //   );
//     // }

//     // Show or update overlay
//     await callService._showOverlay(phoneNumber, callType);

//     // Additional call handling (e.g., spam detection, contact lookup, etc.)
//     final contactInfo = await CallerApiService().getNumberInfo(phoneNumber);
//     // final spamInfo = await _checkSpamDatabase(phoneNumber);
    
//     // Share additional data with overlay
//     await FlutterOverlayWindow.shareData(
//       jsonEncode({
//         'type': 'call_details',
//         'phoneNumber': phoneNumber,
//         'callType': callType.toString(),
//         'contactName': contactInfo!.name,
//         // 'isSpam': spamInfo.isSpam,
//         // 'spamScore': spamInfo.score,
//         'timestamp': DateTime.now().toIso8601String(),
//       }),
//     );

//   } catch (e) {
//     log('Error handling call: $e');
//     rethrow;
//   }
// }

//   Future<void> _showOverlay(String phoneNumber, CallScreenType callType) async {
//     if (await overlay.FlutterOverlayWindow.isActive()) return;

//     // Pass the call data to the overlay
//     final params = {
//       'phoneNumber': phoneNumber,
//       'callType': callType,
//     };

//     // Set overlay size and position with the parameters
//     await overlay.FlutterOverlayWindow.showOverlay(
//       enableDrag: true,
//       overlayTitle: "Call Overlay",
//       overlayContent: "$callType Call from $phoneNumber",
//       flag: overlay.OverlayFlag.defaultFlag,
//       alignment: overlay.OverlayAlignment.topCenter,
//       visibility: overlay.NotificationVisibility.visibilityPublic,
//       positionGravity: overlay.PositionGravity.auto,
//       width: overlay.WindowSize.matchParent,
//       height: overlay.WindowSize.matchParent,
//       // overlayParams: params,
//     );
//   }

// Future<void> _hideOverlay() async {
//   if (await overlay.FlutterOverlayWindow.isActive()) {
//     await overlay.FlutterOverlayWindow.closeOverlay();
//   }
// }

 

//   Future<void> _requestPermissions() async {
//     final notificationStatus = await Permission.notification.request();
//     if (notificationStatus.isDenied) {
//       throw Exception('Notification permission is required');
//     }

//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.phone,
//       Permission.contacts,
//       Permission.notification,
//       Permission.systemAlertWindow,
//     ].request();

//     bool isPermanentlyDenied =
//         statuses.values.any((status) => status.isPermanentlyDenied);
//     if (isPermanentlyDenied) {
//       await openAppSettings();
//       throw Exception('Please grant required permissions in settings');
//     }

//     bool allGranted = statuses.values.every((status) => status.isGranted);
//     if (!allGranted) {
//       throw Exception('Required permissions not granted');
//     }

//     await Permission.ignoreBatteryOptimizations.request();
//     await Permission.systemAlertWindow.request();
//   }
// void _updateServiceNotification(
//   ServiceInstance service,
//   String title,
//   String content,
// ) {
//   if (service is AndroidServiceInstance) {
//     service.setForegroundNotificationInfo(
//       title: title,
//       content: content,
//     );
//   }
// }
//   Future<void> _initializeNotifications() async {
//     const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
//       'incoming_calls',
//       'Incoming Calls',
//       description: 'Notifications for incoming calls',
//       importance: Importance.max,
//       enableVibration: true,
//       enableLights: true,
//     );

//     const AndroidNotificationChannel spamChannel = AndroidNotificationChannel(
//       'spam_calls',
//       'Spam Calls',
//       description: 'Notifications for spam calls',
//       importance: Importance.max,
//       enableVibration: true,
//       enableLights: true,
//     );

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(callChannel);

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(spamChannel);

//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const DarwinInitializationSettings initializationSettingsIOS =
//         DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );

//     const InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );

//     await flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: _onNotificationTapped,
//     );
//   }

  


//   // @pragma('vm:entry-point')
//   // static void _onServiceStart(ServiceInstance service) async {
//   //   try {
//   //     if (service is AndroidServiceInstance) {
//   //       service.setAsForegroundService();
//   //       service.setAutoStartOnBootMode(true);
//   //     }

//   //     PhoneState.stream.listen((event) async {
//   //       if (event.number == null || event.number!.isEmpty) {
//   //         log('Received call event with empty number');
//   //         return;
//   //       }

//   //       try {
//   //         switch (event.status) {
//   //           case PhoneStateStatus.CALL_INCOMING:
//   //             await _handleIncomingCall(event.number!, service);
//   //             break;
//   //           case PhoneStateStatus.CALL_STARTED:
//   //             await _handleCallStarted(event.number!, service);
//   //             break;
//   //           case PhoneStateStatus.CALL_ENDED:
//   //             await _handleCallEnded(service);
//   //             break;
//   //           default:
//   //             break;
//   //         }
//   //       } catch (e) {
//   //         log('Error handling call state: $e');
//   //       }
//   //     });
//   //   } catch (e) {
//   //     log('Error in onServiceStart: $e');
//   //   }
//   // }

  // @pragma('vm:entry-point')
  // static Future<bool> _onIosBackground(ServiceInstance service) async {
  //   return true;
  // }

//   static Future<void> _handleIncomingCall(
//       String phoneNumber, ServiceInstance service) async {
//     try {
//       // await showCallBubble(phoneNumber);
//       await _showNotification(phoneNumber);

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: 'Active Call',
//           content: 'Call from $phoneNumber',
//         );
//       }

//       final isSpam = await _checkIfSpam(phoneNumber);
//       if (isSpam) {
//         await _showSpamNotification(phoneNumber);
//       }
//     } catch (e) {
//       log('Error handling incoming call: $e');
//     }
//   }

//   static Future<void> _handleCallStarted(
//       String phoneNumber, ServiceInstance service) async {
//     try {
//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: 'Call in Progress',
//           content: 'Connected with $phoneNumber',
//         );
//       }
//     } catch (e) {
//       log('Error handling call start: $e');
//     }
//   }

//   static Future<void> _handleCallEnded(ServiceInstance service) async {
//     try {
//       // await _hideCallBubble();
//       await flutterLocalNotificationsPlugin.cancel(999);
//       await flutterLocalNotificationsPlugin.cancel(1000);

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: 'Call Protection Active',
//           content: 'Monitoring incoming calls',
//         );
//       }
//     } catch (e) {
//       log('Error handling call end: $e');
//     }
//   }

//   static Future<bool> _checkIfSpam(String phoneNumber) async {
//     // Implement your spam checking logic here
//     // This is a placeholder implementation
//     return false;
//   }

//   static Future<void> _showNotification(String phoneNumber) async {
//     try {
//       const AndroidNotificationDetails androidDetails =
//           AndroidNotificationDetails(
//         'incoming_calls',
//         'Incoming Calls',
//         channelDescription: 'Notifications for incoming calls',
//         importance: Importance.max,
//         priority: Priority.high,
//         fullScreenIntent: true, // Ensure this is set
//         category: AndroidNotificationCategory.call,
//         // visibility: NotificationVisibility.public,
//       );

//       const NotificationDetails notificationDetails = NotificationDetails(
//         android: androidDetails,
//       );

//       await flutterLocalNotificationsPlugin.show(
//         999,
//         'Incoming Call',
//         'From: $phoneNumber',
//         notificationDetails,
//         payload: phoneNumber,
//       );
//     } catch (e) {
//       log('Error showing notification: $e');
//     }
//   }

//   static Future<void> _showSpamNotification(String phoneNumber) async {
//     try {
//       const AndroidNotificationDetails androidDetails =
//           AndroidNotificationDetails(
//         'spam_calls',
//         'Spam Calls',
//         channelDescription: 'Notifications for spam calls',
//         importance: Importance.max,
//         priority: Priority.high,
//         fullScreenIntent: true,
//         category: AndroidNotificationCategory.call,
//         // visibility: NotificationVisibility.public,
//       );

//       const NotificationDetails notificationDetails = NotificationDetails(
//         android: androidDetails,
//       );

//       await flutterLocalNotificationsPlugin.show(
//         1000,
//         'Spam Call Warning!',
//         'Suspicious call from: $phoneNumber',
//         notificationDetails,
//         payload: phoneNumber,
//       );
//     } catch (e) {
//       log('Error showing spam notification: $e');
//     }
//   }

//   static void _onNotificationTapped(NotificationResponse response) {
//     try {
//       if (response.payload != null) {
//         Navigator.push(
//           navigatorKey.currentState!.context,
//           MaterialPageRoute(
//             builder: (context) => AlertScreen(
//               phoneNumber: response.payload!,
//               callType: CallScreenType.incoming, // Updated to use new enum
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       log('Error handling notification tap: $e');
//     }
//   }
// }


// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';

// import 'package:call_log/call_log.dart';
// import 'package:flutter/material.dart';
// import 'package:phone_state/phone_state.dart';
// import 'package:phone_state_background/phone_state_background.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:secureconnect/controllers/caller_api_service.dart';
// import 'package:secureconnect/main.dart';
// import 'package:secureconnect/models/caller_info.dart';
// import 'package:secureconnect/screens/alert.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';

// @pragma('vm:entry-point')
// void backgroundServiceHandler() async {
//   final service = FlutterBackgroundService();
  
//   // Initialize service
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onServiceStart,
//       autoStart: true,
//       isForegroundMode: true,
//       initialNotificationTitle: 'Call Detection Service',
//       initialNotificationContent: 'Running in background',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// @pragma('vm:entry-point')
// Future<void> onServiceStart(ServiceInstance service) async {
//   if (service is AndroidServiceInstance) {
//     service.setAsForegroundService();
//   }
  
//   await initializeCallDetection();
// }

// // Add the missing initialization function
// Future<void> initializeCallDetection() async {
//   // Initialize notifications
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
      
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
      
//   const InitializationSettings initializationSettings =
//       InitializationSettings(android: initializationSettingsAndroid);
      
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) async {
//       if (response.payload == 'alert_screen') {
//         // Handle notification tap
//       }
//     },
//   );

//   // Request necessary permissions
//   await Future.wait([
//     Permission.phone.request(),
//     Permission.notification.request(),
//     PhoneStateBackground.checkPermission(),
//   ]);

//   // Initialize phone state background handler
//   await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
// }

// @pragma('vm:entry-point')
// Future<void> phoneStateBackgroundCallbackHandler(
//   PhoneStateBackgroundEvent event,
//   String number,
//   int duration,
// ) async {
//   final callDetectionService = CallDetectionService();
//   await callDetectionService.initializeBackground();

//   switch (event) {
//     case PhoneStateBackgroundEvent.incomingstart:
//     case PhoneStateBackgroundEvent.outgoingstart:
//       // Launch app and show alert
//       await _launchApp();
//       await callDetectionService.handleCall(
//         number, 
//         isIncoming: event == PhoneStateBackgroundEvent.incomingstart
//       );
//       break;
//     case PhoneStateBackgroundEvent.incomingend:
//     case PhoneStateBackgroundEvent.outgoingend:
//       await callDetectionService.handleCallEnd();
//       break;
//     default:
//       break;
//   }
// }

// Future<void> _launchApp() async {
//   final notificationsPlugin = FlutterLocalNotificationsPlugin();
  
//   const androidDetails = AndroidNotificationDetails(
//     'call_detection_channel',
//     'Call Detection',
//     importance: Importance.max,
//     priority: Priority.high,
//     fullScreenIntent: true, // This is crucial for launching on locked screen
//     showWhen: true,
//   );

//   const notificationDetails = NotificationDetails(android: androidDetails);
  
//   await notificationsPlugin.show(
//     0,
//     'Incoming Call',
//     'Tap to view caller details',
//     notificationDetails,
//     payload: 'alert_screen',
//   );
// }

// class CallDetectionService {
//   static final CallDetectionService _instance = CallDetectionService._internal();
//   final CallerApiService _callerApiService = CallerApiService();
//   late Database database;
//   bool _isAlertScreenShowing = false;
//   Timer? _screenTimer;
//   factory CallDetectionService() => _instance;
//   CallDetectionService._internal();

//   Future<void> initialize(BuildContext context) async {
//     await _initPermissions();
//     await initializeBackground();
//     await _initPhoneStateListener();
//     await _initializeNotifications();
//     backgroundServiceHandler();
//   }
//   Future<void> _initializeNotifications() async {
//     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
//         FlutterLocalNotificationsPlugin();
    
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
    
//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
    
//     await flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) async {
//         final payload = response.payload;
//         if (payload != null) {
//           final data = json.decode(payload);
//           await _handleNotificationTap(data);
//         }
//       },
//     );
//   }
//    Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
//     if (data['type'] == 'call_alert' && !_isAlertScreenShowing) {
//       final phoneNumber = data['phoneNumber'];
//       final isIncoming = data['isIncoming'];
      
//       if (navigatorKey.currentState != null) {
//         await Navigator.push(
//           navigatorKey.currentState!.context,
//           MaterialPageRoute(
//             builder: (context) => AlertScreen(
//               phoneNumber: phoneNumber,
//               callType: isIncoming ? CallType.incoming : CallType.outgoing,
//             ),
//           ),
//         );
//       }
//     }
//   }

//   Future<void> initializeBackground() async {
//     await _initDatabase();
//     await _requestPermissions();
//   }

//   Future<void> _initPermissions() async {
//     final permissions = await Future.wait([
//       Permission.phone.request(),
//       Permission.notification.request(),
//     ]);
    
//     for (var status in permissions) {
//       if (!status.isGranted) {
//         log('Warning: Not all permissions granted. Some features may not work.');
//       }
//     }
//   }
//    Future<void> _requestPermissions() async {
//     await PhoneStateBackground.checkPermission();
//     await PhoneStateBackground.requestPermissions();
    
//     // Request other necessary permissions
//     final notificationsPlugin = FlutterLocalNotificationsPlugin();
//     await notificationsPlugin.resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
//   }

//   Future<void> _initPhoneStateListener() async {
//     PhoneState.stream.listen((event) async {
//       switch (event.status) {
//         case PhoneStateStatus.CALL_INCOMING:
//           await handleCall(event.number ?? '', isIncoming: true);
//           break;
//         case PhoneStateStatus.CALL_ENDED:
//           await handleCallEnd();
//           break;
//         default:
//           break;
//       }
//     });
//   }

// Future<void> handleCall(String phoneNumber, {required bool isIncoming}) async {
//     try {
//       // Keep screen on
//       await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
//       await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_TURN_SCREEN_ON);
//       await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SHOW_WHEN_LOCKED);
      
//       _screenTimer?.cancel();

//       final callerInfo = await _callerApiService.getNumberInfo(phoneNumber);
      
//       // Show notification with caller info
//       await _showCallerNotification(phoneNumber, isIncoming, callerInfo);
      
//       if (callerInfo?.isSpam == true) {
//         await _logSpamCall(phoneNumber, isIncoming, callerInfo!);
//       }

//       // Only show alert screen if app is in foreground
//       if (!Platform.isAndroid || await isAppInForeground()) {
//         await _showAlertScreen(phoneNumber, isIncoming);
//       }
      
//       _screenTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
//         await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
//       });
      
//     } catch (e) {
//       log('Error handling call: $e');
//     }
//   }
//    Future<void> _showCallerNotification(
//     String phoneNumber, 
//     bool isIncoming, 
//     CallerInfo? callerInfo
//   ) async {
//     final notificationsPlugin = FlutterLocalNotificationsPlugin();
    
//     final androidDetails = AndroidNotificationDetails(
//       'call_detection_channel',
//       'Call Detection',
//       channelDescription: 'Notifications for incoming and outgoing calls',
//       importance: Importance.max,
//       priority: Priority.high,
//       fullScreenIntent: true,
//       showWhen: true,
//       category: AndroidNotificationCategory.call,
//       styleInformation: BigTextStyleInformation(
//         _buildNotificationText(callerInfo, phoneNumber, isIncoming),
//       ),
//     );

//     final notificationDetails = NotificationDetails(android: androidDetails);
    
//     final payload = json.encode({
//       'type': 'call_alert',
//       'phoneNumber': phoneNumber,
//       'isIncoming': isIncoming,
//     });

//     await notificationsPlugin.show(
//       0,
//       _getNotificationTitle(isIncoming),
//       _buildNotificationText(callerInfo, phoneNumber, isIncoming),
//       notificationDetails,
//       payload: payload,
//     );
//   }

//   String _getNotificationTitle(bool isIncoming) {
//     return isIncoming ? 'Incoming Call' : 'Outgoing Call';
//   }

//   String _buildNotificationText(
//     CallerInfo? callerInfo, 
//     String phoneNumber,
//     bool isIncoming,
//   ) {
//     final buffer = StringBuffer();
    
//     if (callerInfo?.name != null) {
//       buffer.writeln('Name: ${callerInfo!.name}');
//     }
    
//     buffer.writeln('Number: $phoneNumber');
    
//     if (callerInfo?.provider != null) {
//       buffer.writeln('Provider: ${callerInfo!.provider}');
//     }
    
//     if (callerInfo?.isSpam == true) {
//       buffer.writeln('⚠️ Potential spam call');
//       if (callerInfo?.spamCount != 0) {
//         buffer.writeln('Reported ${callerInfo!.spamCount} times');
//       }
//     }
    
//     buffer.writeln('\nTap to view more details');
    
//     return buffer.toString();
//   }

//   Future<bool> isAppInForeground() async {
//     final lifecycleState = await _getAppLifecycleState();
//     return lifecycleState == AppLifecycleState.resumed;
//   }

//   Future<AppLifecycleState> _getAppLifecycleState() async {
//     final completer = Completer<AppLifecycleState>();
    
//     // Use a timer to ensure we get a value even if no state change occurs
//     Timer(const Duration(milliseconds: 100), () {
//       if (!completer.isCompleted) {
//         completer.complete(WidgetsBinding.instance.lifecycleState ?? 
//                          AppLifecycleState.detached);
//       }
//     });
    
//     return completer.future;
//   }


//    Future<void> handleCallEnd() async {
//     _screenTimer?.cancel();
//     if (_isAlertScreenShowing && navigatorKey.currentState != null) {
//       navigatorKey.currentState!.pop();
//       _isAlertScreenShowing = false;
//     }
//     await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
//   }

//  Future<void> _showAlertScreen(String phoneNumber, bool isIncoming) async {
//     if (!_isAlertScreenShowing && navigatorKey.currentState != null) {
//       _isAlertScreenShowing = true;
      
//       try {
//         await showDialog(
//           context: navigatorKey.currentState!.context,
//           barrierDismissible: false,
//           useSafeArea: false, // Allow full screen display
//           builder: (BuildContext dialogContext) => WillPopScope(
//             onWillPop: () async => false,
//             child: AlertScreen(
//               phoneNumber: phoneNumber,
//               callType: isIncoming ? CallType.incoming : CallType.outgoing,
              
//             ),
//           ),
//         );
//       } catch (e) {
//         log('Error showing alert screen: $e');
//         _isAlertScreenShowing = false;
//       }
//     }
//   }

//   Future<void> _initDatabase() async {
//     database = await openDatabase(
//       join(await getDatabasesPath(), 'spam_calls.db'),
//       onCreate: (db, version) {
//         return db.execute(
//           '''CREATE TABLE spam_calls(
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             phoneNumber TEXT,
//             timestamp INTEGER,
//             callType TEXT,
//             name TEXT,
//             isSpam INTEGER,
//             spamCount INTEGER,
//             provider TEXT,
//             country TEXT,
//             numberType TEXT
//           )'''
//         );
//       },
//       version: 1,
//     );
//   }


//   Future<void> _logSpamCall(String phoneNumber, bool isIncoming, CallerInfo callerInfo) async {
//   final spamCall = SpamCall(
//     phoneNumber: phoneNumber,
//     timestamp: DateTime.now(),
//     callType: isIncoming ? 'incoming' : 'outgoing',
//     name: callerInfo.name,
//     isSpam: callerInfo.isSpam,
//     spamCount: callerInfo.spamCount,
//     provider: callerInfo.provider,
//     country: callerInfo.country,
//     numberType: callerInfo.numberType,
//   );

//   try {
//     await database.insert(
//       'spam_calls',
//       spamCall.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   } catch (e) {
//     log('Error logging spam call: $e');
//   }
// }

// }
// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';

// import 'package:call_log/call_log.dart';
// import 'package:flutter/material.dart';
// import 'package:phone_state/phone_state.dart';
// import 'package:phone_state_background/phone_state_background.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:secureconnect/controllers/caller_api_service.dart';
// import 'package:secureconnect/main.dart';
// import 'package:secureconnect/models/caller_info.dart';
// import 'package:secureconnect/screens/alert.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';

// @pragma('vm:entry-point')
// void backgroundServiceHandler() async {
//   final service = FlutterBackgroundService();
  
//   // Initialize service
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onServiceStart,
//       autoStart: true,
//       isForegroundMode: true,
//       initialNotificationTitle: 'Call Detection Service',
//       initialNotificationContent: 'Running in background',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// @pragma('vm:entry-point')
// Future<void> onServiceStart(ServiceInstance service) async {
//   if (service is AndroidServiceInstance) {
//     service.setAsForegroundService();
//   }
  
//   await initializeCallDetection();
// }

// // Add the missing initialization function
// Future<void> initializeCallDetection() async {
//   // Initialize notifications
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
      
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
      
//   const InitializationSettings initializationSettings =
//       InitializationSettings(android: initializationSettingsAndroid);
      
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) async {
//       if (response.payload == 'alert_screen') {
//         // Handle notification tap
//       }
//     },
//   );

//   // Request necessary permissions
//   await Future.wait([
//     Permission.phone.request(),
//     Permission.notification.request(),
//     PhoneStateBackground.checkPermission(),
//   ]);

//   // Initialize phone state background handler
//   await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
// }

// @pragma('vm:entry-point')
// Future<void> phoneStateBackgroundCallbackHandler(
//   PhoneStateBackgroundEvent event,
//   String number,
//   int duration,
// ) async {
//   final callDetectionService = CallDetectionService();
//   await callDetectionService.initializeBackground();

//   switch (event) {
//     case PhoneStateBackgroundEvent.incomingstart:
//     case PhoneStateBackgroundEvent.outgoingstart:
//       // Launch app and show alert
//       await _launchApp();
//       await callDetectionService.handleCall(
//         number, 
//         isIncoming: event == PhoneStateBackgroundEvent.incomingstart
//       );
//       break;
//     case PhoneStateBackgroundEvent.incomingend:
//     case PhoneStateBackgroundEvent.outgoingend:
//       await callDetectionService.handleCallEnd();
//       break;
//     default:
//       break;
//   }
// }

// Future<void> _launchApp() async {
//   final notificationsPlugin = FlutterLocalNotificationsPlugin();
  
//   const androidDetails = AndroidNotificationDetails(
//     'call_detection_channel',
//     'Call Detection',
//     importance: Importance.max,
//     priority: Priority.high,
//     fullScreenIntent: true, // This is crucial for launching on locked screen
//     showWhen: true,
//   );

//   const notificationDetails = NotificationDetails(android: androidDetails);
  
//   await notificationsPlugin.show(
//     0,
//     'Incoming Call',
//     'Tap to view caller details',
//     notificationDetails,
//     payload: 'alert_screen',
//   );
// }

// class CallDetectionService {
//   static final CallDetectionService _instance = CallDetectionService._internal();
//   final CallerApiService _callerApiService = CallerApiService();
//   late Database database;
//   bool _isAlertScreenShowing = false;
//   Timer? _screenTimer;
//   factory CallDetectionService() => _instance;
//   CallDetectionService._internal();

//   Future<void> initialize(BuildContext context) async {
//     await _initPermissions();
//     await initializeBackground();
//     await _initPhoneStateListener();
//     await _initializeNotifications();
//     backgroundServiceHandler();
//   }
//   Future<void> _initializeNotifications() async {
//     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
//         FlutterLocalNotificationsPlugin();
    
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
    
//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
    
//     await flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) async {
//         final payload = response.payload;
//         if (payload != null) {
//           final data = json.decode(payload);
//           await _handleNotificationTap(data);
//         }
//       },
//     );
//   }
//    Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
//     if (data['type'] == 'call_alert' && !_isAlertScreenShowing) {
//       final phoneNumber = data['phoneNumber'];
//       final isIncoming = data['isIncoming'];
      
//       if (navigatorKey.currentState != null) {
//         await Navigator.push(
//           navigatorKey.currentState!.context,
//           MaterialPageRoute(
//             builder: (context) => AlertScreen(
//               phoneNumber: phoneNumber,
//               callType: isIncoming ? CallType.incoming : CallType.outgoing,
//             ),
//           ),
//         );
//       }
//     }
//   }

//   Future<void> initializeBackground() async {
//     await _initDatabase();
//     await _requestPermissions();
//   }

//   Future<void> _initPermissions() async {
//     final permissions = await Future.wait([
//       Permission.phone.request(),
//       Permission.notification.request(),
//     ]);
    
//     for (var status in permissions) {
//       if (!status.isGranted) {
//         log('Warning: Not all permissions granted. Some features may not work.');
//       }
//     }
//   }
//    Future<void> _requestPermissions() async {
//     await PhoneStateBackground.checkPermission();
//     await PhoneStateBackground.requestPermissions();
    
//     // Request other necessary permissions
//     final notificationsPlugin = FlutterLocalNotificationsPlugin();
//     await notificationsPlugin.resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
//   }

//   Future<void> _initPhoneStateListener() async {
//     PhoneState.stream.listen((event) async {
//       switch (event.status) {
//         case PhoneStateStatus.CALL_INCOMING:
//           await handleCall(event.number ?? '', isIncoming: true);
//           break;
//         case PhoneStateStatus.CALL_ENDED:
//           await handleCallEnd();
//           break;
//         default:
//           break;
//       }
//     });
//   }

// Future<void> handleCall(String phoneNumber, {required bool isIncoming}) async {
//     try {
//       // Keep screen on
//       await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
//       await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_TURN_SCREEN_ON);
//       await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SHOW_WHEN_LOCKED);
      
//       _screenTimer?.cancel();

//       final callerInfo = await _callerApiService.getNumberInfo(phoneNumber);
      
//       // Show notification with caller info
//       await _showCallerNotification(phoneNumber, isIncoming, callerInfo);
      
//       if (callerInfo?.isSpam == true) {
//         await _logSpamCall(phoneNumber, isIncoming, callerInfo!);
//       }

//       // Only show alert screen if app is in foreground
//       if (!Platform.isAndroid || await isAppInForeground()) {
//         await _showAlertScreen(phoneNumber, isIncoming);
//       }
      
//       _screenTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
//         await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
//       });
      
//     } catch (e) {
//       log('Error handling call: $e');
//     }
//   }
//    Future<void> _showCallerNotification(
//     String phoneNumber, 
//     bool isIncoming, 
//     CallerInfo? callerInfo
//   ) async {
//     final notificationsPlugin = FlutterLocalNotificationsPlugin();
    
//     final androidDetails = AndroidNotificationDetails(
//       'call_detection_channel',
//       'Call Detection',
//       channelDescription: 'Notifications for incoming and outgoing calls',
//       importance: Importance.max,
//       priority: Priority.high,
//       fullScreenIntent: true,
//       showWhen: true,
//       category: AndroidNotificationCategory.call,
//       styleInformation: BigTextStyleInformation(
//         _buildNotificationText(callerInfo, phoneNumber, isIncoming),
//       ),
//     );

//     final notificationDetails = NotificationDetails(android: androidDetails);
    
//     final payload = json.encode({
//       'type': 'call_alert',
//       'phoneNumber': phoneNumber,
//       'isIncoming': isIncoming,
//     });

//     await notificationsPlugin.show(
//       0,
//       _getNotificationTitle(isIncoming),
//       _buildNotificationText(callerInfo, phoneNumber, isIncoming),
//       notificationDetails,
//       payload: payload,
//     );
//   }

//   String _getNotificationTitle(bool isIncoming) {
//     return isIncoming ? 'Incoming Call' : 'Outgoing Call';
//   }

//   String _buildNotificationText(
//     CallerInfo? callerInfo, 
//     String phoneNumber,
//     bool isIncoming,
//   ) {
//     final buffer = StringBuffer();
    
//     if (callerInfo?.name != null) {
//       buffer.writeln('Name: ${callerInfo!.name}');
//     }
    
//     buffer.writeln('Number: $phoneNumber');
    
//     if (callerInfo?.provider != null) {
//       buffer.writeln('Provider: ${callerInfo!.provider}');
//     }
    
//     if (callerInfo?.isSpam == true) {
//       buffer.writeln('⚠️ Potential spam call');
//       if (callerInfo?.spamCount != 0) {
//         buffer.writeln('Reported ${callerInfo!.spamCount} times');
//       }
//     }
    
//     buffer.writeln('\nTap to view more details');
    
//     return buffer.toString();
//   }

//   Future<bool> isAppInForeground() async {
//     final lifecycleState = await _getAppLifecycleState();
//     return lifecycleState == AppLifecycleState.resumed;
//   }

//   Future<AppLifecycleState> _getAppLifecycleState() async {
//     final completer = Completer<AppLifecycleState>();
    
//     // Use a timer to ensure we get a value even if no state change occurs
//     Timer(const Duration(milliseconds: 100), () {
//       if (!completer.isCompleted) {
//         completer.complete(WidgetsBinding.instance.lifecycleState ?? 
//                          AppLifecycleState.detached);
//       }
//     });
    
//     return completer.future;
//   }


//    Future<void> handleCallEnd() async {
//     _screenTimer?.cancel();
//     if (_isAlertScreenShowing && navigatorKey.currentState != null) {
//       navigatorKey.currentState!.pop();
//       _isAlertScreenShowing = false;
//     }
//     await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
//   }

//  Future<void> _showAlertScreen(String phoneNumber, bool isIncoming) async {
//     if (!_isAlertScreenShowing && navigatorKey.currentState != null) {
//       _isAlertScreenShowing = true;
      
//       try {
//         await showDialog(
//           context: navigatorKey.currentState!.context,
//           barrierDismissible: false,
//           useSafeArea: false, // Allow full screen display
//           builder: (BuildContext dialogContext) => WillPopScope(
//             onWillPop: () async => false,
//             child: AlertScreen(
//               phoneNumber: phoneNumber,
//               callType: isIncoming ? CallType.incoming : CallType.outgoing,
              
//             ),
//           ),
//         );
//       } catch (e) {
//         log('Error showing alert screen: $e');
//         _isAlertScreenShowing = false;
//       }
//     }
//   }

//   Future<void> _initDatabase() async {
//     database = await openDatabase(
//       join(await getDatabasesPath(), 'spam_calls.db'),
//       onCreate: (db, version) {
//         return db.execute(
//           '''CREATE TABLE spam_calls(
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             phoneNumber TEXT,
//             timestamp INTEGER,
//             callType TEXT,
//             name TEXT,
//             isSpam INTEGER,
//             spamCount INTEGER,
//             provider TEXT,
//             country TEXT,
//             numberType TEXT
//           )'''
//         );
//       },
//       version: 1,
//     );
//   }


//   Future<void> _logSpamCall(String phoneNumber, bool isIncoming, CallerInfo callerInfo) async {
//   final spamCall = SpamCall(
//     phoneNumber: phoneNumber,
//     timestamp: DateTime.now(),
//     callType: isIncoming ? 'incoming' : 'outgoing',
//     name: callerInfo.name,
//     isSpam: callerInfo.isSpam,
//     spamCount: callerInfo.spamCount,
//     provider: callerInfo.provider,
//     country: callerInfo.country,
//     numberType: callerInfo.numberType,
//   );

//   try {
//     await database.insert(
//       'spam_calls',
//       spamCall.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   } catch (e) {
//     log('Error logging spam call: $e');
//   }
// }

// }