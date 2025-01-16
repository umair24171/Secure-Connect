import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secureconnect/screens/home.dart';
import 'package:secureconnect/screens/start.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  

 
  @override
  void initState() {
    super.initState();
    // Navigate to start screen after 3 seconds
    Future.delayed(const Duration(seconds: 8), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Replace 'StartScreen' with your actual start screen widget name
          builder: (context) => FirebaseAuth.instance.currentUser!=null?Home() :StartScreen(),
        ),
      );
    });
 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff66C7F4),
      body: Center(
        child: Container(
          height: 140,
          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// Create your StartScreen widget