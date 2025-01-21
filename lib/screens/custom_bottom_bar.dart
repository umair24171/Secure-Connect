import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:secureconnect/controllers/call_detection_service.dart';
import 'package:secureconnect/screens/calls.dart';
import 'package:secureconnect/screens/home.dart';
import 'package:secureconnect/screens/settings.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:dash_bubble/dash_bubble.dart';

class CustomBottomBar extends StatefulWidget {
  const CustomBottomBar({Key? key}) : super(key: key);

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  int _selectedIndex = 0;
  bool _servicesInitialized = false;
  bool _bubblePermissionGranted = false;

  final List<Widget> _screens = [
    const Home(),
    const Calls(),
    const Center(child: Text('Stats')),
    Settings(),
  ];

  @override
  void initState() {
    super.initState();
    initializeCallServices();
    // _initializeServices();
  }

     initializeCallServices()async{
      

       final bool? granted = await FlutterOverlayWindow.isPermissionGranted();
       if(granted?? false){

       }else{
final bool? status = await FlutterOverlayWindow.requestPermission();
       }

 /// request overlay permission
 /// it will open the overlay settings page and return `true` once the permission granted.
 
        await initializeCallService();

    }

  // Future<bool> _checkAndRequestBubblePermission() async {
  //   try {
  //     // First check if we already have permission
  //     // bool? hasPermission = await DashBubble.instance.hasOverlayPermission();

  //     // if (hasPermission == true) {
  //     //   return true;
  //     // }

  //     // If we don't have permission, request it
  //     // bool granted = await DashBubble.instance.requestOverlayPermission();

  //     // If permission is still not granted after request, show dialog
  //     // if (!granted && mounted) {
  //     //   await _showBubblePermissionDialog();
  //     // }

  //     // return granted;
  //   } catch (e) {
  //     debugPrint('Error checking bubble permission: $e');
  //     return false;
  //   }
  // }

  Future<void> _showBubblePermissionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Overlay Permission Required'),
          content: const Text(
            'This app needs overlay permission to show call bubbles. '
            'Please grant this permission in settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                // Check permission again after returning from settings
                if (mounted) {
                  // _bubblePermissionGranted =
                  //     await _checkAndRequestBubblePermission();
                  setState(() {});
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally show a message that some features won't work
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Some features may not work without overlay permission'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeServices() async {
    try {
      // Check bubble permission first
      // _bubblePermissionGranted = await _checkAndRequestBubblePermission();

      if (!_bubblePermissionGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Call bubbles will not work without overlay permission'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Check other permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.phone,
        Permission.contacts,
        Permission.notification,
        Permission.systemAlertWindow,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted && mounted) {
        _showPermissionDialog('Permissions Required',
            'Please grant all required permissions for the app to work properly.');
        return;
      }

      // Initialize call service
      await initializeCallService();

      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error initializing services: $e');
      }
    }
  }

  void _showPermissionDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              // Check permissions again after returning from settings
              if (mounted) {
                _initializeServices();
              }
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeServices();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeServices();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIcon(0, Icons.home),
                _buildIcon(1, Icons.phone),
                _buildIcon(2, Icons.bar_chart),
                _buildIcon(3, Icons.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1FAAEA) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF1FAAEA),
          size: 28,
        ),
      ),
    );
  }
}