import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CallBlockingService {
   static const MethodChannel _channel = 
      MethodChannel('com.app.secureconnect.contactblocker');
  static Future<void> _showBlockingPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Number Blocking Permissions'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('To block phone numbers, this app needs special permissions.'),
                SizedBox(height: 10),
                Text('Please:'),
                Text('1. Go to Phone Settings'),
                Text('2. Find "Apps" or "Application Manager"'),
                Text('3. Select "Default Apps"'),
                Text('4. Choose "Phone App"'),
                Text('5. Set this app as default'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                await _openAppSettings();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openAppSettings() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String packageName = packageInfo.packageName;

    final Uri settingsUri = Uri.parse('package:$packageName');
    if (await canLaunchUrl(settingsUri)) {
      await launchUrl(settingsUri);
    }
  }

  static Future<bool> blockContact(String phoneNumber, BuildContext context) async {
    try {
      final bool result = await _channel.invokeMethod(
        'blockNumber', 
        {'phoneNumber': phoneNumber}
      );
      
      if (!result) {
        await _showBlockingPermissionDialog(context);
      }
      
      return result;
    } on PlatformException catch (e) {
      print('Blocking error: ${e.message}');
      return false;
    }
  }
}