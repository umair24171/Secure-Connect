import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/caller_info.dart';
import 'caller_api_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Event;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log('🚀 WorkManager task: $task');
    try {
      if (task == 'callMonitoring') {
        log('✅ Call monitoring heartbeat');
      }
      return Future.value(true);
    } catch (e) {
      log('❌ WorkManager error: $e');
      return Future.value(false);
    }
  });
}

class ModernCallService {
  static final ModernCallService _instance = ModernCallService._internal();
  factory ModernCallService() => _instance;
  ModernCallService._internal();

  final CallerApiService _apiService = CallerApiService();
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  bool _isInitialized = false;
  bool _isCallActive = false;
  String? _lastProcessedNumber;
  
  final Map<String, CallerInfo> _callerCache = {};

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    log('🚀 Initializing Modern Call Service');
    
    try {
      await _loadCache();
      await _requestPermissions();
      await _initializeWorkManager();
      _listenToCallEvents();
      _listenToCallKitActions();
      
      _isInitialized = true;
      log('✅ Modern Call Service initialized successfully');
    } catch (e, stack) {
      log('❌ Error initializing: $e\n$stack');
      rethrow;
    }
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString('caller_info_cache');
      
      if (cacheJson != null && cacheJson.isNotEmpty) {
        final Map<String, dynamic> cacheMap = json.decode(cacheJson);
        cacheMap.forEach((key, value) {
          try {
            _callerCache[key] = CallerInfo.fromJson(value as Map<String, dynamic>);
          } catch (e) {
            log('⚠️ Skipping corrupted cache entry: $key');
          }
        });
        log('✅ Loaded ${_callerCache.length} cached entries');
      }
    } catch (e) {
      log('⚠️ Cache load error: $e');
    }
  }

  Future<void> _saveToCache(String phoneNumber, CallerInfo info) async {
    try {
      _callerCache[phoneNumber] = info;
      final prefs = await SharedPreferences.getInstance();
      final cacheMap = _callerCache.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString('caller_info_cache', json.encode(cacheMap));
      log('💾 Cached: $phoneNumber');
    } catch (e) {
      log('⚠️ Cache save error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.phone,
      Permission.contacts,
      Permission.notification,
      Permission.systemAlertWindow,
    ].request();
    
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

 // In modern_call_detection_service.dart, UPDATE this method:

Future<void> _initializeWorkManager() async {
  // 🔥 DISABLED: WorkManager not needed - native BroadcastReceiver handles everything
  // The spam notifications were coming from this!
  
  /*
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  
  await Workmanager().registerPeriodicTask(
    'call-monitor',
    'callMonitoring',
    frequency: const Duration(minutes: 15),
  );
  */
  
  log('✅ WorkManager disabled (using native BroadcastReceiver instead)');
}

  void _listenToCallEvents() {
    _phoneStateSubscription = PhoneState.stream.listen((event) async {
      log('📞 Phone state: ${event.status}');
      
      if (event.number == null || event.number!.isEmpty) return;
      
      switch (event.status) {
        case PhoneStateStatus.CALL_INCOMING:
          log('📲 CALL_INCOMING detected via PhoneState');
          await _handleIncomingCall(event.number!);
          break;
          
        case PhoneStateStatus.CALL_ENDED:
          log('📴 Call ended');
          _isCallActive = false;
          _lastProcessedNumber = null;
          await FlutterCallkitIncoming.endAllCalls();
          break;
          
        default:
          break;
      }
    });
    
    log('✅ Phone state listener active');
  }

  // 🔥 PUBLIC: Handle call from native (updates existing native screen)
  Future<void> handleCallFromNative(String phoneNumber) async {
    log('🔥 handleCallFromNative: $phoneNumber');
    
    // Native already showed basic screen, now update with full info
    await _updateNativeCallScreen(phoneNumber);
  }

  Future<void> _handleIncomingCall(String phoneNumber) async {
    log('📲 INCOMING: $phoneNumber');
    
    // Prevent duplicate processing
    if (_lastProcessedNumber == phoneNumber) {
      log('⚠️ Already processing this number, skipping');
      return;
    }
    
    if (_isCallActive) {
      log('⚠️ Call screen already active, skipping');
      return;
    }
    
    _isCallActive = true;
    _lastProcessedNumber = phoneNumber;
    
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)+]'), '');
    
    try {
      // 🔥 STEP 1: Check cache (instant)
      CallerInfo? cachedInfo = _callerCache[cleanNumber];
      if (cachedInfo != null) {
        log('⚡ CACHE HIT: ${cachedInfo.name}');
        await _showCallScreen(
          phoneNumber: phoneNumber,
          callerName: cachedInfo.name ?? phoneNumber,
          isIncoming: true,
          callerInfo: cachedInfo,
        );
        return;
      }
      
      log('🔍 Cache miss - fetching fresh data...');
      
      // 🔥 STEP 2: Check contacts with 2 second timeout
      String? contactName;
      try {
        log('📇 Checking contacts (max 2s)...');
        contactName = await _getContactName(phoneNumber)
            .timeout(Duration(seconds: 2));
        
        if (contactName != null && contactName.isNotEmpty) {
          log('✅ CONTACT FOUND: $contactName');
          
          await _showCallScreen(
            phoneNumber: phoneNumber,
            callerName: contactName,
            isIncoming: true,
            callerInfo: null,
          );
          
          _fetchApiInBackground(phoneNumber, cleanNumber);
          return;
        } else {
          log('⚠️ No contact found');
        }
      } catch (e) {
        log('⚠️ Contact lookup timeout/error: $e');
      }
      
      // 🔥 STEP 3: Wait for API (4 seconds)
      CallerInfo? callerInfo;
      try {
        log('⏳ Waiting for API (max 4s)...');
        callerInfo = await _apiService.getNumberInfo(phoneNumber)
            .timeout(Duration(seconds: 4));
        
        if (callerInfo != null) {
          log('✅ API SUCCESS: ${callerInfo.name}');
          await _saveToCache(cleanNumber, callerInfo);
        }
      } catch (e) {
        log('❌ API failed: $e');
      }
      
      String displayName;
      if (callerInfo?.name != null && callerInfo!.name!.isNotEmpty) {
        displayName = callerInfo.name!;
        log('🌐 Using API name');
      } else {
        displayName = phoneNumber;
        log('📱 Using phone number');
      }
      
      await _showCallScreen(
        phoneNumber: phoneNumber,
        callerName: displayName,
        isIncoming: true,
        callerInfo: callerInfo,
      );
      
    } catch (e, stack) {
      log('❌ ERROR: $e\n$stack');
      _isCallActive = false;
      _lastProcessedNumber = null;
      
      try {
        await _showCallScreen(
          phoneNumber: phoneNumber,
          callerName: phoneNumber,
          isIncoming: true,
        );
      } catch (e2) {
        log('❌ FALLBACK FAILED: $e2');
      }
    }
  }

  // 🔥 Update the native-shown call screen with full caller info
  Future<void> _updateNativeCallScreen(String phoneNumber) async {
    log('🔄 Updating native call screen with full info');
    
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)+]'), '');
    
    try {
      // Quick check cache first
      CallerInfo? cachedInfo = _callerCache[cleanNumber];
      if (cachedInfo != null) {
        log('⚡ Using cached info for update');
        await _showCallScreen(
          phoneNumber: phoneNumber,
          callerName: cachedInfo.name ?? phoneNumber,
          isIncoming: true,
          callerInfo: cachedInfo,
        );
        return;
      }
      
      // Quick contact check
      String? contactName;
      try {
        contactName = await _getContactName(phoneNumber)
            .timeout(Duration(seconds: 1));
        
        if (contactName != null) {
          log('✅ Contact found for update: $contactName');
          await _showCallScreen(
            phoneNumber: phoneNumber,
            callerName: contactName,
            isIncoming: true,
            callerInfo: null,
          );
          
          // Fetch API in background for future
          _fetchApiInBackground(phoneNumber, cleanNumber);
          return;
        }
      } catch (e) {
        log('⚠️ Contact check timeout');
      }
      
      // Try API
      try {
        final callerInfo = await _apiService.getNumberInfo(phoneNumber)
            .timeout(Duration(seconds: 3));
        
        if (callerInfo != null) {
          log('✅ API info fetched for update');
          await _saveToCache(cleanNumber, callerInfo);
          
          await _showCallScreen(
            phoneNumber: phoneNumber,
            callerName: callerInfo.name ?? phoneNumber,
            isIncoming: true,
            callerInfo: callerInfo,
          );
        }
      } catch (e) {
        log('⚠️ API timeout for update');
      }
      
    } catch (e) {
      log('❌ Update failed: $e');
    }
  }

  void _fetchApiInBackground(String phoneNumber, String cleanNumber) {
    Future.microtask(() async {
      try {
        log('🔄 Background API fetch started...');
        final callerInfo = await _apiService.getNumberInfo(phoneNumber)
            .timeout(Duration(seconds: 5));
        
        if (callerInfo != null) {
          log('✅ Background API: ${callerInfo.name}');
          await _saveToCache(cleanNumber, callerInfo);
        }
      } catch (e) {
        log('⚠️ Background API failed: $e');
      }
    });
  }

 Future<void> _showCallScreen({
  required String phoneNumber,
  required String callerName,
  required bool isIncoming,
  CallerInfo? callerInfo,
}) async {
  // 🔥 REMOVED: Don't end calls before showing!
  // This was causing the screen to disappear immediately
  /*
  try {
    await FlutterCallkitIncoming.endAllCalls();
    await Future.delayed(Duration(milliseconds: 100));
  } catch (e) {
    log('⚠️ Error ending previous calls: $e');
  }
  */
  
  final backgroundColor = callerInfo?.isSpam == true ? '#EF4444' : '#0EA5E9';
  final displayName = callerInfo?.isSpam == true 
      ? '⚠️ SPAM: $callerName' 
      : callerName;
  
  final params = CallKitParams(
    id: '${phoneNumber.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
    nameCaller: displayName,
    appName: 'SecureConnect',
    avatar: callerInfo?.photoUrl,
    handle: phoneNumber,
    type: 0,
    textAccept: 'Accept',
    textDecline: 'Decline',
    duration: 30000,
    android: AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'silent',
      backgroundColor: backgroundColor,
      backgroundUrl: '',
      actionColor: '#10B981',
      textColor: '#ffffff',
      incomingCallNotificationChannelName: 'incoming_call_channel',
      missedCallNotificationChannelName: 'missed_call_channel',
      isShowCallID: true,
      isShowFullLockedScreen: true,  // 🔥 ADD THIS
    ),
    ios: IOSParams(
      iconName: 'AppIcon',
      handleType: 'generic',
      ringtonePath: 'silent',
      supportsVideo: false,
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
    ),
  );

  try {
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    log('✅ DISPLAYED: $displayName');
  } catch (e, stack) {
    log('❌ Failed to show call screen: $e\n$stack');
  }
}

  void _listenToCallKitActions() {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      log('🎯 EVENT: ${event.event}');
      
      switch (event.event) {
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          log('📴 Ending call');
          _isCallActive = false;
          _lastProcessedNumber = null;
          await FlutterCallkitIncoming.endAllCalls();
          break;
        default:
          break;
      }
    });
  }

  Future<String?> _getContactName(String phoneNumber) async {
    try {
      if (!await FlutterContacts.requestPermission()) return null;
      
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)+]'), '');
      
      for (var contact in contacts) {
        for (var phone in contact.phones) {
          final cleanContact = phone.number.replaceAll(RegExp(r'[\s\-\(\)+]'), '');
          
          final last10 = cleanNumber.length >= 10 
              ? cleanNumber.substring(cleanNumber.length - 10) 
              : cleanNumber;
          final contactLast10 = cleanContact.length >= 10 
              ? cleanContact.substring(cleanContact.length - 10) 
              : cleanContact;
          
          if (last10 == contactLast10) {
            return contact.displayName;
          }
        }
      }
    } catch (e) {
      log('❌ Contact error: $e');
    }
    return null;
  }

  void dispose() {
    _phoneStateSubscription?.cancel();
    _apiService.dispose();
  }
}