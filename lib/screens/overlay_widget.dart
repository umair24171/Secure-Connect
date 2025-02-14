import 'dart:convert';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:secureconnect/controllers/call_detection_service.dart';
import 'package:secureconnect/controllers/caller_api_service.dart';
import 'package:secureconnect/models/caller_info.dart';
import 'package:secureconnect/screens/alert.dart';
import 'dart:developer' as developer;

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  final CallerApiService _callerApiService = CallerApiService();
  String phoneNumber = 'Unknown';
  CallScreenType callType = CallScreenType.incoming;
  Map<String, dynamic> callData = {};
  CallerInfo? _callerInfo;
  bool _isLoading = true;
String? contactName;
  @override
  void initState() {
    super.initState();
    developer.log('OverlayWidget initialized', name: 'overlay_widget');
    _setupOverlayListener();
  }

 void _setupOverlayListener() {
  FlutterOverlayWindow.overlayListener.listen((event) {
    developer.log('Received overlay event: $event', name: 'overlay_widget');
    try {
      final data = jsonDecode(event);
      developer.log('Parsed data: $data', name: 'overlay_widget');
      
      // Separate state update from data parsing
      _updateStateAndFetchInfo(data);
    } catch (e) {
      developer.log('Error parsing overlay data: $e', name: 'overlay_widget');
    }
  });
}

void _updateStateAndFetchInfo(Map<String, dynamic> data) async{
  // Capture values before potential widget disposal
  final number = data['phoneNumber'] ?? 'Unknown';
  final type = data['callType'] != null 
    ? _parseCallType(data['callType']) 
    : CallScreenType.incoming;  

  // Use a post-frame callback to ensure widget is still mounted
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      setState(() {
        phoneNumber = number;
        callType = type;
        _isLoading = true;
      });
      // _fetchContactName();
      
      // Run fetch in a microtask to avoid potential race conditions
      Future.microtask(() {
        _fetchCallerInfo(number);
      });
    }
  });
}
Future<void> _fetchContactName() async {
    try {
      final contacts = await ContactsService.getContactsForPhone(phoneNumber);
      if (contacts.isNotEmpty) {
        setState(() {
          contactName = contacts.first.displayName;
        });
      }
    } catch (e) {
      developer.log('Error fetching contact: $e');
    }
  }

Future<void> _fetchCallerInfo(String number) async {
  if (!mounted) return;

  try {
    final info = await _callerApiService.getNumberInfo(number);
    
    if (mounted) {
      setState(() {
        _callerInfo = info;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Caller info fetch error: $e', name: 'overlay_widget');
    }
  }
}

  CallScreenType _parseCallType(String type) {
    final cleanType = type.split('.').last.toLowerCase();
    
    switch (cleanType) {
      case 'incoming':
        return CallScreenType.incoming;
      case 'outgoing':
        return CallScreenType.outgoing;
      case 'missed':
        return CallScreenType.missed;
      default:
        return CallScreenType.incoming;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertScreen(
      phoneNumber: phoneNumber,
      callType: callType,
      callerInfo: _callerInfo,
      isLoading: _isLoading,
    );
  }
}