import 'package:flutter/material.dart';
import 'package:secureconnect/screens/selectage.dart';
import 'package:secureconnect/screens/signup.dart';

class StartScreen extends StatelessWidget {
  StartScreen({super.key});
  String fontFamily = 'Roboto';

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xffffffff),
      body: Container(
        color: Color(0xffffffff),
        width: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: size.height * 0.05, // 5% of screen height
                  ),
                  Container(
                    height: size.height * 0.1,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      // 4% of screen height
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.07, // 2% of screen height
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Your safety start here! Stay Secure.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: size.width * 0.04, // Responsive font size
                          fontWeight: FontWeight.w500,
                          fontFamily: fontFamily),
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.04,
                  ),
                  Container(
                    height: size.height * 0.29,
                    child: Image.asset(
                      'assets/images/mobile.png',
                      fit: BoxFit.cover,
                      // 25% of screen height
                    ),
                  ),
                ],
              ),
            ),
            // Bottom buttons section
            Padding(
              padding: EdgeInsets.only(
                bottom: size.height * 0.08,
                left: 26,
                right: 26,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Color(0xffDFF6FF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13))),
                        onPressed: () async {
                          final selectedAge = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SelectAge()));

                          if (context.mounted && selectedAge != null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        Signup(selectedAge: selectedAge)));
                          }
                        },
                        child: Text(
                          'Select age',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: fontFamily,
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.w700),
                        )),
                  ),
                  SizedBox(
                    height: size.height * 0.02,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Color(0xff058B1E),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13))),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      Signup(selectedAge: '')));
                        },
                        child: Text(
                          'Get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xffffffff),
                              fontFamily: fontFamily,
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.w500),
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
