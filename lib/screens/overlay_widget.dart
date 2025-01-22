import 'dart:convert';

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

        setState(() {
          callData = data;
          phoneNumber = data['phoneNumber'] ?? 'Unknown';
          if (data['callType'] != null) {
            callType = _parseCallType(data['callType']);
          }
        });
        
        _fetchCallerInfo(phoneNumber);
      } catch (e) {
        developer.log('Error parsing overlay data: $e', name: 'overlay_widget');
      }
    });
  }

  Future<void> _fetchCallerInfo(String number) async {
    developer.log('Starting caller info fetch', name: 'overlay_widget');

    if (!mounted) {
      developer.log('Widget not mounted, canceling API call', name: 'overlay_widget');
      return;
    }

    try {
      developer.log('Calling API for number: $number', name: 'overlay_widget');
      
      // Add artificial delay to ensure initialization is complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      final info = await _callerApiService.getNumberInfo(number);
      
      if (!mounted) return;

      setState(() {
        _callerInfo = info;
        _isLoading = false;
      });
    } catch (e, stack) {
      developer.log(
        'Error fetching caller info',
        name: 'overlay_widget',
        error: e,
        stackTrace: stack
      );
      
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
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