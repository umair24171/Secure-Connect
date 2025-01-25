import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class BlockCalls extends StatefulWidget {
  const BlockCalls({super.key});

  @override
  State<BlockCalls> createState() => _BlockCallsState();
}

class _BlockCallsState extends State<BlockCalls> {
  final String fontFamily = 'Roboto';
  final TextEditingController search = TextEditingController();
  String searchQuery = '';
  List<Map<String, dynamic>> blockedContacts = [];
  List<Map<String, dynamic>> filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchBlockedContacts();
  }

  Future<void> _fetchBlockedContacts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('blockedContacts')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        blockedContacts = querySnapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data()
        }).toList();
        filteredContacts = List.from(blockedContacts);
      });
    } catch (e) {
      print('Error fetching blocked contacts: $e');
    }
  }

  Future<void> _unblockContact(String contactId, String number, String name) async {
    try {
      // Attempt to unblock via device settings
      final unblockUri = Uri.parse('tel:unblock:$number');
      if (await canLaunchUrl(unblockUri)) {
        await launchUrl(unblockUri);
      }

      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('blockedContacts')
          .doc(contactId)
          .delete();

      // Refresh the list
      await _fetchBlockedContacts();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name unblocked')),
      );
    } catch (error) {
      print('Error unblocking contact: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to unblock contact')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final size = MediaQuery.of(context).size;

    // Calculate responsive values
    final double paddingScale = size.width * 0.04;
    final double iconSize = size.width * 0.06;
    final double fontSize = size.width * 0.04;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: size.height * 0.1,
        backgroundColor: Color(0xff66C7F4),
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            
            margin: EdgeInsets.only(left: 10),
            height: size.height * 0.04,
            width: size.height * 0.04,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xffDFF6FF),
            ),
            child: Center(
              child: Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: size.height * 0.03,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Block Calls',
          style: TextStyle(
            color: Colors.white,
            fontFamily: fontFamily,
            fontSize: size.width * 0.058,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xffffffff),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(13),
            topRight: Radius.circular(13),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: paddingScale,
            vertical: paddingScale * 0.75,
          ),
          child: Column(
            children: [
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
                shadowColor: const MaterialStatePropertyAll(Color(0xffDFF6FF)),
                backgroundColor:
                    const MaterialStatePropertyAll(Color(0xffDFF6FF)),
                elevation: const MaterialStatePropertyAll(2),
                controller: search,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                    filteredContacts = blockedContacts.where((contact) => 
                      contact['number'].contains(searchQuery)
                    ).toList();
                  });
                },
              ),
              SizedBox(height: size.height * 0.025),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return BlockedNumberItem(
                      size: size,
                      fontSize: fontSize,
                      fontFamily: fontFamily,
                      number: contact['number'],
                      onUnblock: () => _unblockContact(
                        contact['id'], 
                        contact['number'], 
                        contact['name'] ?? 'Unknown'
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlockedNumberItem extends StatelessWidget {
  final Size size;
  final double fontSize;
  final String fontFamily;
  final String number;
  final VoidCallback onUnblock;

  const BlockedNumberItem({
    super.key,
    required this.size,
    required this.fontSize,
    required this.fontFamily,
    required this.number,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.015),
      child: Row(
        children: [
          Container(
            height: size.width * 0.12,
            width: size.width * 0.12,
            decoration: const BoxDecoration(
              color: Color(0xffDFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_2_outlined,
              size: size.width * 0.08,
              color: Colors.black,
            ),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Text(
              number,
              style: TextStyle(
                fontFamily: fontFamily,
                color: const Color(0xff393939),
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          TextButton(
            onPressed: onUnblock,
            child: Text(
              'Unblock',
              style: TextStyle(
                color: Colors.black,
                fontFamily: fontFamily,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}