import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  _HelpAndSupportScreenState createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  final String fontFamily = 'Roboto';
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> _submitSupportTicket() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a support ticket')),
      );
      return;
    }

    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user.uid,
        'email': user.email,
        'subject': _subjectController.text,
        'message': _messageController.text,
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket submitted successfully')),
      );

      // Clear text fields
      _subjectController.clear();
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit support ticket')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingScale = size.width * 0.04;
    final double fontSize = size.width * 0.04;
    final double headerFontSize = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xff66C7F4),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: paddingScale,
                vertical: paddingScale * 0.6,
              ),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffDFF6FF),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: paddingScale),
                  Text(
                    'Help & Support',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: fontFamily,
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Support Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(paddingScale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FAQs Section
                        _buildSectionTitle('Frequently Asked Questions', fontSize),
                        _buildFAQItem('How to block a number?', fontSize),
                        _buildFAQItem('Can I recover blocked contacts?', fontSize),
                        _buildFAQItem('How does the scam detection work?', fontSize),

                        SizedBox(height: paddingScale),

                        // Contact Support Section
                        _buildSectionTitle('Contact Support', fontSize),
                        TextField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            hintText: 'Subject',
                            fillColor: const Color(0xffDFF6FF),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: paddingScale * 0.5),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Describe your issue',
                            fillColor: const Color(0xffDFF6FF),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: paddingScale),
                        ElevatedButton(
                          onPressed: _submitSupportTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff66C7F4),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Submit Ticket',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: fontFamily,
                              fontSize: fontSize,
                            ),
                          ),
                        ),

                        // Contact Info
                        SizedBox(height: paddingScale),
                        _buildSectionTitle('Contact Information', fontSize),
                        _buildContactInfo('Email', 'support@callblocker.com', fontSize),
                        _buildContactInfo('Phone', '+1 (800) CALL-HELP', fontSize),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize * 1.2,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.help_outline, color: Color(0xff66C7F4)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              question,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                color: Colors.black87,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.contact_support, color: Color(0xff66C7F4)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSize * 0.9,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}