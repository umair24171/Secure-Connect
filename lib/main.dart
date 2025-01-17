import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secureconnect/controllers/call_detection_service.dart';
import 'package:secureconnect/controllers/userprovider.dart';
import 'package:secureconnect/firebase_options.dart';
import 'package:secureconnect/screens/splash.dart';



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize call detection first
  await initializeCallDetection();
  
  // Then initialize background service
 backgroundServiceHandler();
  runApp(MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => UserProvider())],
      child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
// late BuildContext _context;


  @override
  Widget build(BuildContext context) {
    //  _context = context;
    return MaterialApp(
       navigatorKey: navigatorKey, // Add the navigator key here
      debugShowCheckedModeBanner: false,
      title: 'Secure Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Splash(),
    );
  }
}

