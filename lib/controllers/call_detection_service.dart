import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:developer' as developer;
// import 'package:dash_bubble/dash_bubble.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:secureconnect/main.dart';
import 'package:secureconnect/screens/alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            await callService.hideOverlay();
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
 final String _kLastCallNumberKey = 'last_call_phone_number';

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
        height: 700,
      );

      developer.log('Overlay created successfully', name: 'call_service');
       final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastCallNumberKey, phoneNumber);
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

   Future<void> hideOverlay() async {
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        
        
        // Show dialog using global navigator key
        _showProceedDialog();
      }
    } catch (e) {
      log('Error hiding overlay: $e');
    }
  }
   Future<String?> _getLastCallPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastCallNumberKey);
  }
  Future<void> clearLastCallNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastCallNumberKey);
  }

    void _showProceedDialog() async {
    final BuildContext? context = navigatorKey.currentContext;
    final String? lastPhoneNumber = await _getLastCallPhoneNumber();
    
    if (context != null && lastPhoneNumber != null) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: ProceedDialog(
              context: dialogContext,
              size: MediaQuery.of(context).size,
              fontFamily: 'Roboto',
              phoneNumber: lastPhoneNumber,
            ),
          );
        },
      );
    }
  }
}
