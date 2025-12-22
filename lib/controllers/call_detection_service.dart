import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secureconnect/main.dart';
import 'package:secureconnect/screens/alert.dart';
import 'package:secureconnect/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

// CRITICAL: Initialize Firebase ONCE at service level
bool _firebaseInitialized = false;

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  log('Starting Call Service');
  
  try {
    // Initialize Firebase FIRST
    if (!_firebaseInitialized) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform
        );
        _firebaseInitialized = true;
        log('Firebase initialized in service');
      } catch (e) {
        log('Firebase already initialized or error: $e');
      }
    }

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setAutoStartOnBootMode(true);
    }

    // Add delay to ensure everything is ready
    await Future.delayed(Duration(seconds: 1));

    PhoneState.stream.listen((event) async {
      if (event.number == null || event.number!.isEmpty) {
        log('Received call event with empty number');
        return;
      }

      final callService = CallService();
      
      try {
        // Add delay between state changes
        await Future.delayed(Duration(milliseconds: 500));
        
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
            // Only show overlay if not already active
            if (!await FlutterOverlayWindow.isActive()) {
              await callService._showOverlay(
                event.number!,
                CallScreenType.outgoing,
              );
            }
            break;
            
          case PhoneStateStatus.CALL_ENDED:
            log('Call ended');
            await callService.hideOverlay();
            break;
            
          default:
            log('Unhandled phone state: ${event.status}');
            break;
        }
      } catch (e, stack) {
        log('Error handling call state: $e');
        log('Stack trace: $stack');
        // Don't crash the service
      }
    });

  } catch (e, stack) {
    log('Error in onServiceStart: $e');
    log('Stack trace: $stack');
  }
}

enum CallScreenType { incoming, outgoing, missed }

Future<void> initializeCallService() async {
  await CallService().initialize();
}

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();
  
  final String _kLastCallNumberKey = 'last_call_phone_number';
  bool _isOverlayActive = false;

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
      if (granted != true) {
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
    
    try {
      // Check if overlay is already active
      final isActive = await FlutterOverlayWindow.isActive();
      
      if (isActive) {
        developer.log('Overlay already active, updating data', name: 'call_service');
        await _updateOverlayData(phoneNumber, callType);
        return;
      }

      // Store phone number BEFORE creating overlay
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastCallNumberKey, phoneNumber);
      
      developer.log('Creating new overlay', name: 'call_service');
      
      // Create overlay with proper error handling
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
      _isOverlayActive = true;
      
      // Add delay before sending data to ensure overlay is ready
      await Future.delayed(Duration(milliseconds: 800));
      await _updateOverlayData(phoneNumber, callType);

    } catch (e, stack) {
      developer.log(
        'Error showing overlay',
        name: 'call_service',
        error: e,
        stackTrace: stack
      );
      _isOverlayActive = false;
      // Don't rethrow - just log the error
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
        _isOverlayActive = false;
        
        // Add delay before showing dialog
        await Future.delayed(Duration(milliseconds: 500));
        _showProceedDialog();
      }
    } catch (e, stack) {
      log('Error hiding overlay: $e');
      log('Stack trace: $stack');
      _isOverlayActive = false;
    }
  }
  
  Future<String?> _getLastCallPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kLastCallNumberKey);
    } catch (e) {
      log('Error getting last call number: $e');
      return null;
    }
  }
  
  Future<void> clearLastCallNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastCallNumberKey);
    } catch (e) {
      log('Error clearing last call number: $e');
    }
  }

  void _showProceedDialog() async {
    try {
      final BuildContext? context = navigatorKey.currentContext;
      final String? lastPhoneNumber = await _getLastCallPhoneNumber();
      
      if (context != null && lastPhoneNumber != null) {
        // Ensure we're on main thread
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
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
        });
      }
    } catch (e, stack) {
      log('Error showing proceed dialog: $e');
      log('Stack trace: $stack');
    }
  }
}