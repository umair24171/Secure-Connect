import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secureconnect/controllers/userprovider.dart';
import 'package:secureconnect/firebase_options.dart';
import 'package:secureconnect/screens/overlay_widget.dart';
import 'package:secureconnect/screens/splash.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Ensure call service is initialized early
  // await CallService().initialize();
  
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create:(context) => UserProvider(),)
    ],
    
    
    child: const MyApp()));
}
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  print('OVERLAY_DEBUG: Starting overlay main'); 
  
 
  runApp(
 const   MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWidget(
      
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Secure Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const Splash(),
    );
  }
}