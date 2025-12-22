import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:secureconnect/controllers/call_detection_service.dart';
import 'package:secureconnect/firebase_options.dart';
import 'package:secureconnect/models/caller_info.dart';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

// screens/alert_screen.dart
class AlertScreen extends StatelessWidget {
 final String phoneNumber;
  final CallScreenType callType;
  final CallerInfo? callerInfo;
  final bool isLoading;
 final String? contactName;

  const AlertScreen({
    super.key,
    required this.phoneNumber,
    required this.callType,
    required this.callerInfo,
    this.contactName,
    required this.isLoading,
  });

  final String fontFamily = 'Roboto';

   Future<void> _proceedWithCall(BuildContext context) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      // Save caller info to Firebase
      await FirebaseFirestore.instance.collection('proceed-calls').add({
        'userId':FirebaseAuth.instance.currentUser?.uid ?? '',
        'phoneNumber': phoneNumber,
        'callerName': callerInfo?.name ?? 'Unknown',
        'callType': callType.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'provider': callerInfo?.provider,
        'country': callerInfo?.country,
        'isSpam': callerInfo?.isSpam ?? false,
        'spamCount': callerInfo?.spamCount ?? 0,
      });

      // Close overlay
       await  CallService().hideOverlay();

      // Close screen
      // Navigator.pop(context);
    } catch (e) {
      developer.log('Error proceeding with call: $e');
    }
  }

  Future<void> _cancelCall(BuildContext context) async {
    try {
      // Close overlay
   await  CallService().hideOverlay();

      // Close screen
      // Navigator.pop(context);
    } catch (e) {
      developer.log('Error canceling call: $e');
    }
  }

  //   final String fontFamily = 'Roboto';
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
 final displayName = contactName??
                        callerInfo?.name ?? 
                        'Unknown Number';
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: const Color(0xff66C7F4),
        body: SafeArea(
          child: Container(
            color: const Color(0xff66C7F4),
            width: double.infinity,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.05),
                            Container(
                              height: size.width * 0.2,
                              width: size.width * 0.2,
                              decoration: const BoxDecoration(
                                color: Color(0xffDFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_2_outlined,
                                  size: 55,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                             displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: fontFamily,
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              phoneNumber,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: fontFamily,
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (callerInfo?.provider != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                '${callerInfo?.provider} - ${callerInfo?.country}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: fontFamily,
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (callerInfo?.isSpam == true ||
                                callerInfo?.spamCount != 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.warning_amber,
                                    color: Color(0xffFFB703),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Scam Alert${callerInfo?.spamCount != 0 ? ' (${callerInfo?.spamCount} reports)' : ''}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: fontFamily,
                                      fontSize: size.width * 0.045,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                ],
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.1,
                          vertical: size.height * 0.07,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff058B1E),
                                shape: const CircleBorder(),
                                fixedSize:
                                    Size(size.width * 0.18, size.width * 0.18),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => _proceedWithCall(context),
                              child: SizedBox.expand(
                                child: Center(
                                  child: Text(
                                    'Proceed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: fontFamily,
                                      fontSize: size.width * 0.04,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffD20D0D),
                                shape: const CircleBorder(),
                                fixedSize:
                                    Size(size.width * 0.18, size.width * 0.18),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => _cancelCall(context),
                              child: SizedBox.expand(
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: fontFamily,
                                      fontSize: size.width * 0.04,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Extract ProceedDialog to a separate widget for better organization
class ProceedDialog extends StatefulWidget {
  final BuildContext context;
  final Size size;
  final String fontFamily;
  final String phoneNumber;

  const ProceedDialog({super.key, 
    required this.context,
    required this.size,
    required this.fontFamily,
    required this.phoneNumber,
  });

  @override
  State<ProceedDialog> createState() => _ProceedDialogState();
}

class _ProceedDialogState extends State<ProceedDialog> {
  bool? didProceed;
  String? selectedReason;

   Future<void> _submitProceedCallData() async {
    if (didProceed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select if you proceeded with the call')),
      );
      return;
    }

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await FirebaseFirestore.instance.collection('proceed-calls').add({
        'phoneNumber': widget.phoneNumber,
        'didProceed': didProceed,
        'proceedReason': didProceed == true ? selectedReason : null,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      // Clear last call number from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_call_phone_number');

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit data: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size.width * 0.85,
      padding: EdgeInsets.all(widget.size.width * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xffE7F8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            'Did you proceed with call?',
            style: TextStyle(
              color: Colors.black,
              fontFamily: widget.fontFamily,
              fontSize: widget.size.width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: widget.size.height * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionRow(true, widget.size, didProceed == true),
              _buildOptionRow(false, widget.size, didProceed == false),
            ],
          ),
          Divider(
            color: const Color(0xff66C7F4),
            thickness: 0.3,
            height: widget.size.height * 0.03,
          ),
          if (didProceed == true) ...[
            Text(
              'Why did you proceed?',
              style: TextStyle(
                color: Colors.black,
                fontFamily: widget.fontFamily,
                fontSize: widget.size.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: widget.size.height * 0.02),
            ...['Trusted source', 'Mistake', 'Urgent need']
                .map(
                  (option) => InkWell(
                    onTap: () => setState(() => selectedReason = option),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: widget.size.height * 0.01),
                      child: Row(
                        children: [
                          Container(
                            height: 30,
                            width: 30,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: selectedReason == option
                                  ? const Color(0xff66C7F4)
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            option,
                            style: TextStyle(
                              color: const Color(0xff5A5A5A),
                              fontFamily: widget.fontFamily,
                              fontSize: widget.size.width * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
          SizedBox(height: widget.size.height * 0.02),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff66C7F4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: Size(0, widget.size.height * 0.045),
                ),
               onPressed: () => _submitProceedCallData(),
                child: Center(
                  child: Text(
                    'Proceed',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: widget.fontFamily,
                      fontSize: widget.size.width * 0.04,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(bool isYes, Size size, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => didProceed = isYes),
      child: Row(
        children: [
          Container(
            height: size.width * 0.03,
            width: size.width * 0.03,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff66C7F4) : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: size.width * 0.02),
          Text(
            isYes ? 'Yes' : 'No',
            style: TextStyle(
              color: const Color(0xff5A5A5A),
              fontFamily: widget.fontFamily,
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}