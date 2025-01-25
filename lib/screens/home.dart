import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:secureconnect/screens/call_logs_screen.dart';
import 'package:secureconnect/screens/feedback.dart';
import 'package:secureconnect/screens/settings.dart';



class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final String fontFamily = 'Roboto';
  final TextEditingController search = TextEditingController();
  String searchQuery = '';

   @override
void initState() {
  super.initState();
  // CallDetectionService().initialize(context);
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;
    final containerHeight = size.height * 0.1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: containerHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xff66C7F4),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.elliptical(
                        size.width / 2, containerHeight * 0.7),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Welcome to Secure connect',
                    style: TextStyle(
                      color: const Color(0xffffffff),
                      fontFamily: fontFamily,
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.02,
                ),
                child: Column(
                  children: [
                    SearchBar(
                      textStyle: const MaterialStatePropertyAll(
                        TextStyle(
                            color: Color(0xff494949), fontFamily: 'Roboto'),
                      ),
                      hintText: 'Search numbers',
                      hintStyle: const MaterialStatePropertyAll(
                        TextStyle(
                            color: Color(0xff494949), fontFamily: 'Roboto'),
                      ),
                      shape: const MaterialStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                      ),
                      surfaceTintColor:
                          const MaterialStatePropertyAll(Color(0xffDFF6FF)),
                      shadowColor:
                          const MaterialStatePropertyAll(Color(0xffDFF6FF)),
                      backgroundColor:
                          const MaterialStatePropertyAll(Color(0xffDFF6FF)),
                      elevation: const MaterialStatePropertyAll(20),
                      controller: search,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    SizedBox(height: size.height * 0.03),
                    ScamDetection(size: size),
                    SizedBox(height: size.height * 0.03),
                    InkWell(
                      onTap: () async{
                         Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CallLogsScreen(callType: "outgoing"),
      ),
    );
                      },
                      child: CallButton(
                        
                        image: 'assets/images/outcall.png',
                        text: 'Outgoing calls',
                        size: size,
                      ),

                    ),
                    SizedBox(height: size.height * 0.02),
                    InkWell(
                      onTap: () async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CallLogsScreen(callType: "incoming"),
      ),
    );
  },
                      child: CallButton(
                        image: 'assets/images/incall.png',
                        text: 'Incoming calls',
                        size: size,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    InkWell(
                       onTap: () async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CallLogsScreen(callType: "missed"),
      ),
    );
  },
                      child: CallButton(
                        image: 'assets/images/misscall.png',
                        text: 'Missed calls',
                        size: size,
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),
                    Wrap(
                      spacing: size.width * 0.04,
                      runSpacing: size.height * 0.01,
                      alignment: WrapAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Settings()));
                          },
                          child: ActionButton(
                            icon: Icons.settings_outlined,
                            text: 'Settings',
                            size: size,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => FeedbackScreen()));
                          },
                          child: ActionButton(
                            icon: Icons.feedback_outlined,
                            text: 'Feedback',
                            size: size,
                          ),
                        ),
                      ],
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
}

class ScamDetection extends StatelessWidget {
  final Size size;

  const ScamDetection({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xffF5E2E2),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.03),
                decoration: const BoxDecoration(
                  color: Color(0xff8F0000),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.cancel_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.02),
              Text(
                'Scam Detection',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: size.width * 0.04,
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            'Likely scam',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: size.width * 0.04,
            ),
          ),
          SizedBox(height: size.height * 0.03),
          Text(
            'Suspicious activity detected for this call.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              fontSize: size.width * 0.035,
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Not a scam',
                style: TextStyle(
                  color: const Color(0xffCA0C0C),
                  fontFamily: 'Roboto',
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff8F0000),
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.03,
                    vertical: size.height * 0.01,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
                onPressed: () {},
                child: Text(
                  'Scam call',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CallButton extends StatelessWidget {
  final String image;
  final String text;
  final Size size;

  const CallButton({
    super.key,
    required this.image,
    required this.text,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffDFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Image.asset(image, height: size.height * 0.03),
          SizedBox(width: size.width * 0.04),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Roboto',
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Size size;

  const ActionButton({
    super.key,
    required this.icon,
    required this.text,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffDFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xff66C7F4)),
          SizedBox(width: size.width * 0.02),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Roboto',
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
