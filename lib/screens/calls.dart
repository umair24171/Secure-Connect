import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_direct_call_plus/flutter_direct_call.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart'; // UPDATED

import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

class Calls extends StatefulWidget {
  const Calls({super.key});

  @override
  State<Calls> createState() => _CallsState();
}

class _CallsState extends State<Calls> {
  final String fontFamily = 'Roboto';
  final TextEditingController search = TextEditingController();
  String searchQuery = '';
  
  List<Contact> contacts = [];
  List<Contact> favoriteContacts = [];
  bool isLoading = true;
  bool hasPermission = false;

  // Simulated call log for iOS (you would typically get this from your backend)
  List<CallInfo> recentCalls = [];

  @override
  void initState() {
    super.initState();
    initializeData();
    // // Initialize demo call data for iOS
    // if (Platform.isIOS) {
    //   initializeDemoCallData();
    // }
  }

  void initializeDemoCallData() {
    // This is where you would typically fetch call data from your backend
    recentCalls = [
      CallInfo(
        name: "John Doe",
        number: "+1234567890",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        callType: CallInfoType.incoming,
      ),
      CallInfo(
        name: "Jane Smith",
        number: "+1987654321",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        callType: CallInfoType.outgoing,
      ),
      // Add more demo calls as needed
    ];
  }

  Future<void> initializeData() async {
    await requestPermissions();
    await _loadContacts();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.contacts,
        Permission.phone,
      ].request();
    } else if (Platform.isIOS) {
      await Permission.contacts.request();
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      isLoading = true;
    });

    // Request contacts permission using flutter_contacts
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() {
        isLoading = false;
        hasPermission = false;
      });
      return;
    }

    try {
      // Load all contacts with properties
      List<Contact> contactsList = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      // Filter out contacts without phone numbers
      List<Contact> validContacts = contactsList.where((contact) {
        return contact.phones.isNotEmpty && 
               contact.displayName.isNotEmpty;
      }).toList();

      // Sort contacts alphabetically
      validContacts.sort((a, b) => 
        a.displayName.compareTo(b.displayName));

      setState(() {
        contacts = validContacts;
        hasPermission = true;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() {
        isLoading = false;
        hasPermission = false;
      });
    }
  }

  List<Contact> getFilteredContacts() {
    if (searchQuery.isEmpty) return contacts;
    return contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final numbers = contact.phones.map((p) => p.number.toLowerCase());
      return name.contains(searchQuery) || 
             numbers.any((number) => number.contains(searchQuery));
    }).toList();
  }

  List<dynamic> getFilteredItems() {
    if (Platform.isIOS) {
      if (searchQuery.isEmpty) return recentCalls;
      return recentCalls.where((call) {
        final name = call.name.toLowerCase();
        final number = call.number.toLowerCase();
        return name.contains(searchQuery) || number.contains(searchQuery);
      }).toList();
    } else {
      // For Android, filter contacts
      if (searchQuery.isEmpty) return contacts;
      return contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final numbers = contact.phones.map((p) => p.number.toLowerCase());
        return name.contains(searchQuery) || 
               numbers.any((number) => number.contains(searchQuery));
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingScale = size.width * 0.04;
    final double iconSize = size.width * 0.05;
    final double fontSize = size.width * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Column(
        children: [
          // App bar
          Container(
            height: size.height * 0.16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xff66C7F4),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(size.width / 2, size.height * 0.05),
              ),
            ),
            child: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Calls',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: fontFamily,
                        fontSize: fontSize * 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    left: paddingScale * 1.1,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: size.width * 0.1,
                        width: size.width * 0.1,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffDFF6FF),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: iconSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(paddingScale),
                      child: Column(
                        children: [
                          // Search Bar
                          SearchBar(
                            textStyle: MaterialStatePropertyAll(
                              TextStyle(
                                color: const Color(0xff494949),
                                fontFamily: fontFamily,
                                fontSize: fontSize,
                              ),
                            ),
                            hintText: 'Search numbers',
                            hintStyle: MaterialStatePropertyAll(
                              TextStyle(
                                color: const Color(0xff494949),
                                fontFamily: fontFamily,
                                fontSize: fontSize,
                              ),
                            ),
                            shape: const MaterialStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(30)),
                              ),
                            ),
                            surfaceTintColor:
                                const MaterialStatePropertyAll(Color(0xffDFF6FF)),
                            shadowColor:
                                const MaterialStatePropertyAll(Color(0xffDFF6FF)),
                            backgroundColor:
                                const MaterialStatePropertyAll(Color(0xffDFF6FF)),
                            elevation: const MaterialStatePropertyAll(2),
                            controller: search,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                          SizedBox(height: size.height * 0.02),
                          // Quick Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              QuickActionButton(
                                size: size,
                                icon: Icons.person_pin_outlined,
                                label: 'Contact',
                                fontSize: fontSize,
                                fontFamily: fontFamily,
                                onTap: () async {
                                  await _loadContacts();
                                },
                              ),
                              QuickActionButton(
                                size: size,
                                icon: Icons.favorite_outline,
                                label: 'Favourites',
                                fontSize: fontSize,
                                fontFamily: fontFamily,
                                onTap: () {
                                  // Show favorites
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: size.height * 0.02),
                          // Call List
                          ...getFilteredItems().map((item) {
                            if (Platform.isIOS) {
                              final call = item as CallInfo;
                              return Padding(
                                padding: EdgeInsets.only(bottom: size.height * 0.015),
                                child: CallListItem(
                                  initial: call.name[0],
                                  name: call.name,
                                  number: call.number,
                                  timestamp: call.timestamp,
                                  callType: call.callType,
                                  size: size,
                                  fontSize: fontSize,
                                  fontFamily: fontFamily,
                                ),
                              );
                            } else {
                              final contact = item as Contact;
                              return Padding(
                                padding: EdgeInsets.only(bottom: size.height * 0.015),
                                child: CallListItem(
                                  initial: contact.displayName.isNotEmpty 
                                      ? contact.displayName[0] 
                                      : '#',
                                  name: contact.displayName.isNotEmpty 
                                      ? contact.displayName 
                                      : 'Unknown',
                                  number: contact.phones.isNotEmpty 
                                      ? contact.phones.first.number 
                                      : '',
                                  timestamp: DateTime.now(),
                                  callType: CallInfoType.incoming,
                                  size: size,
                                  fontSize: fontSize,
                                  fontFamily: fontFamily,
                                ),
                              );
                            }
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// New class to handle call information uniformly across platforms
class CallInfo {
  final String name;
  final String number;
  final DateTime timestamp;
  final CallInfoType callType;

  CallInfo({
    required this.name,
    required this.number,
    required this.timestamp,
    required this.callType,
  });
}

enum CallInfoType {
  incoming,
  outgoing,
  missed,
}

class CallListItem extends StatelessWidget {
  final String initial;
  final String name;
  final String number;
  final DateTime timestamp;
  final CallInfoType callType;
  final Size size;
  final double fontSize;
  final String fontFamily;

  const CallListItem({
    super.key,
    required this.initial,
    required this.name,
    required this.number,
    required this.timestamp,
    required this.callType,
    required this.size,
    required this.fontSize,
    required this.fontFamily,
  });

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  IconData _getCallIcon(CallInfoType callType) {
    switch (callType) {
      case CallInfoType.incoming:
        return Icons.call_received_outlined;
      case CallInfoType.outgoing:
        return Icons.call_made_outlined;
      case CallInfoType.missed:
        return Icons.call_missed_outgoing_outlined;
    }
  }

  Color _getCallIconColor(CallInfoType callType) {
    switch (callType) {
      case CallInfoType.missed:
        return Colors.red;
      case CallInfoType.incoming:
        return const Color(0xff04960D);
      case CallInfoType.outgoing:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: size.width * 0.1,
          width: size.width * 0.1,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xff1AB7F4),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize * 1.5,
                fontWeight: FontWeight.w700,
                fontFamily: fontFamily,
              ),
            ),
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: fontFamily,
                  fontSize: fontSize * 1.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Icon(
                    _getCallIcon(callType),
                    color: _getCallIconColor(callType),
                    size: fontSize,
                  ),
                  SizedBox(width: size.width * 0.01),
                  Icon(
                    Icons.file_present_outlined,
                    color: const Color(0xff848484),
                    size: fontSize,
                  ),
                  SizedBox(width: size.width * 0.01),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: const Color(0xff848484),
                      fontFamily: fontFamily,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () async{
           await FlutterDirectCall.makeDirectCall(number);
            //  if(res?? false){
            //   log('call $res');
            //  }
          },
          child: Icon(
            Icons.call,
            size: fontSize * 1.2,
            color: const Color(0xff444444), 
          ),
        ),
        const SizedBox(width: 5,),
       
  IconButton(
 onPressed: () async {
   // Check if number exists in blocked contacts
   final existingBlockQuery = await FirebaseFirestore.instance
       .collection('blockedContacts')
       .doc(number)
       .get();

   if (existingBlockQuery.exists) {
     // Redirect to phone's unblock settings
     final Uri unblockUri = Uri.parse('tel:unblock:$number');
     if (await canLaunchUrl(unblockUri)) {
       await launchUrl(unblockUri);
       
       // Remove from Firebase block list
       await existingBlockQuery.reference.delete();

       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('$name unblocked'))
       );
     } else {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Unable to open unblocking interface'))
       );
     }
   } else {
     // Block flow (similar to previous implementation)
     final Uri blockUri = Uri.parse('tel:block:$number');
     if (await canLaunchUrl(blockUri)) {
       await launchUrl(blockUri);
       
       await FirebaseFirestore.instance.collection('blockedContacts').doc(number).set({
         'name': name,
         'number': number,
         'blockedAt': FieldValue.serverTimestamp(),
         'userId':FirebaseAuth.instance.currentUser?.uid??''
       });

       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('$name blocked'))
       );
     } else {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Unable to open blocking interface'))
       );
     }
   }
 }, 
 icon: Icon(
   Icons.block, 
   size: fontSize * 1.2,
   color: const Color(0xff444444),
 )
)
      ],
    );
  }
  
}

class QuickActionButton extends StatelessWidget {
  final Size size;
  final IconData icon;
  final String label;
  final double fontSize;
  final String fontFamily;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.size,
    required this.icon,
    required this.label,
    required this.fontSize,
    required this.fontFamily,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size.height * 0.11,
        width: size.width * 0.28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: const Color(0xffDFF6FF),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xff414141),
              size: size.width * 0.06,
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xff414141),
                fontFamily: fontFamily,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}