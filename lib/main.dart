import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:secureconnect/controllers/call_detection_service.dart';
import 'package:secureconnect/controllers/userprovider.dart';
import 'package:secureconnect/firebase_options.dart';
import 'package:secureconnect/screens/splash.dart';
import 'dart:developer';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔥 Method channel to receive calls from native Android
const platform = MethodChannel('com.secureconnect/call_handler');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 🔥 Initialize call service
  try {
    await ModernCallService().initialize();
    log('✅ ModernCallService initialized');
  } catch (e) {
    log('❌ Error initializing ModernCallService: $e');
  }
  
  // 🔥 Setup method channel listener BEFORE running app
  _setupNativeCallHandler();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// 🔥 Handle incoming calls from native (when app was terminated)
void _setupNativeCallHandler() {
  platform.setMethodCallHandler((call) async {
    log('📲 Native method call: ${call.method}');
    
    try {
      if (call.method == 'handleIncomingCall') {
        final phoneNumber = call.arguments['phoneNumber'] as String?;
        
        if (phoneNumber != null) {
          log('📞 Handling call from native: $phoneNumber');
          
          // 🔥 Give Flutter engine 500ms to initialize, then handle the call
          await Future.delayed(Duration(milliseconds: 500));
          
          // 🔥 Directly trigger the call handling
          await ModernCallService().handleCallFromNative(phoneNumber);
        }
      }
    } catch (e, stack) {
      log('❌ Error in native call handler: $e\n$stack');
    }
  });
  
  log('✅ Native call handler setup complete');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'SecureConnect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const Splash(),
    );
  }
}