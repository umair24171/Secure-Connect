import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secureconnect/controllers/account_deletion_controller.dart';
import 'package:secureconnect/controllers/share_services.dart';
import 'package:secureconnect/screens/blockcalls.dart';
import 'package:secureconnect/screens/calls.dart';
import 'package:secureconnect/screens/help_support.dart';
import 'package:secureconnect/screens/login.dart';
import 'package:secureconnect/screens/scamcalls.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});
  final String fontFamily = 'Roboto';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingScale = size.width * 0.05; // Responsive padding

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: size.height * 0.1,
          backgroundColor: Color(0xff66C7F4),
          leadingWidth: size.height * 0.1,
          leading: Container(
            margin: EdgeInsets.only(left: 10),
            height: 35,
            width:35,
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
          centerTitle: true,
          title: Text(
            'Settings',
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
                    topRight: Radius.circular(13))),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: paddingScale,
                // vertical: paddingScale * 0.75,
              ).copyWith(top:paddingScale * 0.75 ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      // Changed to ListView for better scrolling
                      children: [
                        InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Calls()));
                            },
                            child: SettingsContainer(
                                Icons.call, 'Calls', '', false)),
                        SizedBox(height: size.height * 0.015),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BlockCalls()));
                          },
                          child: SettingsContainer(null, 'Block Calls',
                              'assets/images/block.png', false),
                        ), // Using image instead of icon
                        SizedBox(height: size.height * 0.015),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Scamcalls()));
                          },
                          child: SettingsContainer(Icons.warning_amber_outlined,
                              'Scam Calls', '', false),
                        ),
                        SizedBox(height: size.height * 0.015),
                       NotificationsSettingsContainer(),
                        SizedBox(height: size.height * 0.015),
                        SettingsContainer(Icons.privacy_tip_outlined,
                            'Privacy & Policy', '', false),
                        SizedBox(height: size.height * 0.015),
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>HelpAndSupportScreen()));
                          },
                          child: SettingsContainer(Icons.help_outline_outlined,
                              'Help & Support', '', false),
                        ),
                        SizedBox(height: size.height * 0.015),
                        InkWell(
                          onTap: ()async {
                             await ShareServices()
                                        .referFriend(FirebaseAuth.instance.currentUser?.uid??'')
                                        .then((value) {
                                      Share.share(value);
                                      
                                    });
                          },
                          child: SettingsContainer(Icons.person_add_alt_1,
                              'Invite a Friend', '', false),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0,),
               
                 ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    padding: EdgeInsets.symmetric(
      vertical: size.height * 0.02,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14)
    )
  ),
  onPressed: () async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      AccountDeletionService deletionService = AccountDeletionService();
      bool success = await deletionService.deleteUserAccount();

      if (success) {
        // Navigate to login or welcome screen
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context)=>LoginScreen()),(route)=>false );
        
        // Optionally show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deleted successfully'))
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account. Please try again.'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  },
  child: Center(
    child: Text(
      'Delete account',
      style: TextStyle(
        color: Color(0xffffffff),
        fontFamily: fontFamily,
        fontSize: size.width * 0.045,
        fontWeight: FontWeight.w500
      ),
    ),
  )
),
                 
                  // SizedBox(height: size.height * 0.03),
                ],
              ),
            )));
  }

 Widget SettingsContainer(
  IconData? icon, 
  String text, 
  String? image, 
  bool hasSwitch, 
  {bool? switchValue, 
  ValueChanged<bool>? onSwitchChanged}
) {
  return Builder(builder: (context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xffDFF6FF), 
        borderRadius: BorderRadius.circular(13)
      ),
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.02,
        horizontal: size.width * 0.04,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: Color(0xff1FAAEA),
                  size: size.width * 0.06,
                )
              else if (image != null)
                Image.asset(
                  image,
                  width: size.width * 0.06,
                  height: size.width * 0.06,
                ),
              SizedBox(width: size.width * 0.03),
              Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Roboto', // Replace with your font
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
          if (hasSwitch)
            Switch(
              value: switchValue ?? false, 
              onChanged: onSwitchChanged,
              activeColor: Color(0xff1FAAEA),
              activeTrackColor: Color(0xff1FAAEA).withOpacity(0.5),
              thumbColor: MaterialStateProperty.all(Colors.white),
            ),
        ],
      ),
    );
  });
}


}


class NotificationsSettingsContainer extends StatefulWidget {
  @override
  _NotificationsSettingsContainerState createState() => _NotificationsSettingsContainerState();
}

class _NotificationsSettingsContainerState extends State<NotificationsSettingsContainer> {
  bool _notificationsEnabled = true;

  Widget SettingsContainer(
  IconData? icon, 
  String text, 
  String? image, 
  bool hasSwitch, 
  {bool? switchValue, 
  ValueChanged<bool>? onSwitchChanged}
) {
  return Builder(builder: (context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xffDFF6FF), 
        borderRadius: BorderRadius.circular(13)
      ),
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.02,
        horizontal: size.width * 0.04,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: Color(0xff1FAAEA),
                  size: size.width * 0.06,
                )
              else if (image != null)
                Image.asset(
                  image,
                  width: size.width * 0.06,
                  height: size.width * 0.06,
                ),
              SizedBox(width: size.width * 0.03),
              Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Roboto', // Replace with your font
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
          if (hasSwitch)
            Switch(
              value: switchValue ?? false, 
              onChanged: onSwitchChanged,
              activeColor: Color(0xff1FAAEA),
              activeTrackColor: Color(0xff1FAAEA).withOpacity(0.5),
              thumbColor: MaterialStateProperty.all(Colors.white),
            ),
        ],
      ),
    );
  });
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SettingsContainer(
      Icons.notifications_none,
      'Notifications',
      '',
      true,
      switchValue: _notificationsEnabled,
      onSwitchChanged: (value) {
        setState(() {
          _notificationsEnabled = value;
          // Optional: Add logic to save notification preference
          // e.g., SharedPreferences or Firebase
        });
      },
    );
  }
}



