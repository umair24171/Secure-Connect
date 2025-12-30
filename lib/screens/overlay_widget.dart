// import 'dart:convert';
// import 'package:flutter_contacts/flutter_contacts.dart';
// import 'package:flutter/material.dart';
// import 'package:secureconnect/controllers/call_detection_service.dart';
// import 'package:secureconnect/controllers/caller_api_service.dart';
// import 'package:secureconnect/models/caller_info.dart';
// import 'package:secureconnect/screens/alert.dart';
// import 'dart:developer' as developer;

// class OverlayWidget extends StatefulWidget {
//   const OverlayWidget({super.key});

//   @override
//   State<OverlayWidget> createState() => _OverlayWidgetState();
// }

// class _OverlayWidgetState extends State<OverlayWidget> {
//   final CallerApiService _callerApiService = CallerApiService();
//   String phoneNumber = 'Unknown';
//   CallScreenType callType = CallScreenType.incoming;
//   CallerInfo? _callerInfo;
//   bool _isLoading = true;
//   String? contactName;
//   bool _dataReceived = false;

//   @override
//   void initState() {
//     super.initState();
//     developer.log('OverlayWidget initialized', name: 'overlay_widget');
//     _setupOverlayListener();
    
//     // Timeout fallback in case data is never received
//     Future.delayed(Duration(seconds: 3), () {
//       if (!_dataReceived && mounted) {
//         developer.log('No data received after 3 seconds, using default', name: 'overlay_widget');
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     });
//   }

//   void _setupOverlayListener() {
//     FlutterOverlayWindow.overlayListener.listen(
//       (event) {
//         developer.log('Received overlay event: $event', name: 'overlay_widget');
        
//         try {
//           if (event == null || event.isEmpty) {
//             developer.log('Empty event received', name: 'overlay_widget');
//             return;
//           }
          
//           final data = jsonDecode(event) as Map<String, dynamic>;
//           developer.log('Parsed data: $data', name: 'overlay_widget');
          
//           _dataReceived = true;
//           _updateStateAndFetchInfo(data);
//         } catch (e, stack) {
//           developer.log('Error parsing overlay data: $e', name: 'overlay_widget');
//           developer.log('Stack trace: $stack', name: 'overlay_widget');
          
//           // Try to continue with default values
//           if (mounted) {
//             setState(() {
//               _isLoading = false;
//             });
//           }
//         }
//       },
//       onError: (error) {
//         developer.log('Overlay listener error: $error', name: 'overlay_widget');
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       },
//     );
//   }

//   void _updateStateAndFetchInfo(Map<String, dynamic> data) async {
//     if (!mounted) return;
    
//     try {
//       // Extract values
//       final number = data['phoneNumber'] as String? ?? 'Unknown';
//       final type = data['callType'] != null 
//         ? _parseCallType(data['callType'] as String) 
//         : CallScreenType.incoming;

//       developer.log('Processing call: $number, type: $type', name: 'overlay_widget');

//       // Update state on main thread
//       if (mounted) {
//         setState(() {
//           phoneNumber = number;
//           callType = type;
//           _isLoading = true;
//         });
//       }
      
//       // Fetch data in background with proper error handling
//       try {
//         // First try to get contact name
//         await _fetchContactName(number);
        
//         // Then fetch caller info from API
//         await _fetchCallerInfo(number);
//       } catch (e) {
//         developer.log('Error fetching info: $e', name: 'overlay_widget');
        
//         // Even if API fails, show UI with what we have
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     } catch (e, stack) {
//       developer.log('Error in _updateStateAndFetchInfo: $e', name: 'overlay_widget');
//       developer.log('Stack trace: $stack', name: 'overlay_widget');
      
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchContactName(String number) async {
//     if (!mounted) return;
    
//     try {
//       // Request permission with error handling
//       bool permissionGranted;
//       try {
//         permissionGranted = await FlutterContacts.requestPermission(readonly: true);
//       } catch (e) {
//         developer.log('Contact permission error: $e', name: 'overlay_widget');
//         return;
//       }

//       if (!permissionGranted) {
//         developer.log('Contact permission denied', name: 'overlay_widget');
//         return;
//       }

//       // Get contacts with timeout
//       final contacts = await Future.any([
//         FlutterContacts.getContacts(
//           withProperties: true,
//           withPhoto: false,
//         ),
//         Future.delayed(Duration(seconds: 2), () => <Contact>[]),
//       ]);

//       if (!mounted || contacts.isEmpty) return;

//       // Clean the phone number for comparison
//       final cleanNumber = number.replaceAll(RegExp(r'[\s\-\(\)+]'), '');
      
//       // Find matching contact
//       for (var contact in contacts) {
//         for (var phone in contact.phones) {
//           final cleanContactNumber = phone.number.replaceAll(RegExp(r'[\s\-\(\)+]'), '');
          
//           // Compare last 10 digits
//           final numberToCompare = cleanNumber.length >= 10 
//               ? cleanNumber.substring(cleanNumber.length - 10) 
//               : cleanNumber;
//           final contactToCompare = cleanContactNumber.length >= 10 
//               ? cleanContactNumber.substring(cleanContactNumber.length - 10) 
//               : cleanContactNumber;
          
//           if (contactToCompare == numberToCompare) {
//             if (mounted) {
//               setState(() {
//                 contactName = contact.displayName;
//               });
//             }
//             developer.log('Found contact: ${contact.displayName}', name: 'overlay_widget');
//             return;
//           }
//         }
//       }
      
//       developer.log('No matching contact found for: $number', name: 'overlay_widget');
//     } catch (e, stack) {
//       developer.log('Error fetching contact: $e', name: 'overlay_widget');
//       developer.log('Stack trace: $stack', name: 'overlay_widget');
//     }
//   }

//   Future<void> _fetchCallerInfo(String number) async {
//     if (!mounted) return;

//     developer.log('Starting API call for: $number', name: 'overlay_widget');

//     try {
//       // Add timeout to API call
//       final info = await Future.any([
//         _callerApiService.getNumberInfo(number),
//         Future.delayed(Duration(seconds: 10), () => null),
//       ]);
      
//       developer.log('API response received: ${info != null}', name: 'overlay_widget');
      
//       if (mounted) {
//         setState(() {
//           _callerInfo = info;
//           _isLoading = false;
//         });
//       }
//     } catch (e, stack) {
//       developer.log('Caller info fetch error: $e', name: 'overlay_widget');
//       developer.log('Stack trace: $stack', name: 'overlay_widget');
      
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   CallScreenType _parseCallType(String type) {
//     final cleanType = type.split('.').last.toLowerCase();
    
//     switch (cleanType) {
//       case 'incoming':
//         return CallScreenType.incoming;
//       case 'outgoing':
//         return CallScreenType.outgoing;
//       case 'missed':
//         return CallScreenType.missed;
//       default:
//         return CallScreenType.incoming;
//     }
//   }

//   @override
//   void dispose() {
//     _callerApiService.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       type: MaterialType.transparency,
//       child: AlertScreen(
//         phoneNumber: phoneNumber,
//         callType: callType,
//         callerInfo: _callerInfo,
//         contactName: contactName,
//         isLoading: _isLoading,
//       ),
//     );
//   }
// }