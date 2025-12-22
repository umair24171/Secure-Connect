import 'dart:convert';

import 'package:flutter_contacts/flutter_contacts.dart'; // UPDATED
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

  void _updateStateAndFetchInfo(Map<String, dynamic> data) async {
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
        
        // Fetch contact name first, then caller info
        Future.microtask(() {
          _fetchContactName(number);
          _fetchCallerInfo(number);
        });
      }
    });
  }

  // UPDATED: Use flutter_contacts instead of contacts_service
  Future<void> _fetchContactName(String number) async {
    try {
      // Request permission if not already granted
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        developer.log('Contact permission denied', name: 'overlay_widget');
        return;
      }

      // Get all contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Clean the phone number for comparison (remove spaces, dashes, etc.)
      final cleanNumber = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // Find matching contact by phone number
      for (var contact in contacts) {
        for (var phone in contact.phones) {
          final cleanContactNumber = phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
          
          // Check if numbers match (compare last 10 digits for better matching)
          if (cleanContactNumber.endsWith(cleanNumber.substring(cleanNumber.length > 10 ? cleanNumber.length - 10 : 0)) ||
              cleanNumber.endsWith(cleanContactNumber.substring(cleanContactNumber.length > 10 ? cleanContactNumber.length - 10 : 0))) {
            
            if (mounted) {
              setState(() {
                contactName = contact.displayName;
              });
            }
            developer.log('Found contact: ${contact.displayName}', name: 'overlay_widget');
            return;
          }
        }
      }
      
      developer.log('No matching contact found for: $number', name: 'overlay_widget');
    } catch (e) {
      developer.log('Error fetching contact: $e', name: 'overlay_widget');
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
      contactName: contactName,
      isLoading: _isLoading,
    );
  }
}