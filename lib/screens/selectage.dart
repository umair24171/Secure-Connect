import 'package:flutter/material.dart';
import 'package:secureconnect/screens/signup.dart';

class SelectAge extends StatefulWidget {
  const SelectAge({super.key});

  @override
  State<SelectAge> createState() => _SelectAgeState();
}

class _SelectAgeState extends State<SelectAge> {
  String fontFamily = 'Roboto';
  String selectedAge = ''; // Variable to store selected age

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      body: SafeArea(
        child: Container(
          color: Color(0xffffffff),
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: size.height * 0.05,
                      ),
                      Text('Select your age group',
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: size.height * 0.1),
                      AgeContainer('Under 18', selectedAge),
                      SizedBox(height: size.height * 0.03),
                      AgeContainer('18-30', selectedAge),
                      SizedBox(height: size.height * 0.03),
                      AgeContainer('31-49', selectedAge),
                      SizedBox(height: size.height * 0.03),
                      AgeContainer('50-59', selectedAge),
                      SizedBox(height: size.height * 0.03),
                      AgeContainer('60+', selectedAge),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, '');
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xff6C6C6C),
                          fontFamily: fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff66C7F4),
                        fixedSize: Size(70, 70),
                        shape: CircleBorder(),
                      ),
                      onPressed: () {
                        Navigator.pop(context, selectedAge);
                      },
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward,
                          color: Color(0xffffffff),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget AgeContainer(String text, String currentSelection) {
    bool isSelected = text == currentSelection;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAge = text;
        });
      },
      child: Container(
        height: 50,
        width: 130,
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xff3399CC) : Color(0xff66C7F4),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }
}
