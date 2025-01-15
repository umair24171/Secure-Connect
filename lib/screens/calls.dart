import 'package:flutter/material.dart';

class Calls extends StatefulWidget {
  const Calls({super.key});

  @override
  State<Calls> createState() => _CallsState();
}

class _CallsState extends State<Calls> {
  final String fontFamily = 'Roboto';
  final TextEditingController search = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingScale = size.width * 0.04;
    final double iconSize = size.width * 0.05;
    final double fontSize = size.width * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Column(
        children: [
          // Custom App Bar with curved bottom
          Container(
            height: size.height * 0.16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xff66C7F4),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.elliptical(size.width / 2, size.height * 0.05),
              ),
            ),
            child: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Title
                  Center(
                    child: Text(
                      'Calls',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: fontFamily,
                        fontSize: fontSize * 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Back Button Container positioned on the left
                  Positioned(
                    left: paddingScale * 1.1,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: size.width * 0.1,
                        width: size.width * 0.1,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffDFF6FF),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: iconSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(paddingScale),
                child: Column(
                  children: [
                    // Search Bar
                    SearchBar(
                      textStyle: MaterialStatePropertyAll(
                        TextStyle(
                          color: const Color(0xff494949),
                          fontFamily: fontFamily,
                          fontSize: fontSize,
                        ),
                      ),
                      hintText: 'Search numbers',
                      hintStyle: MaterialStatePropertyAll(
                        TextStyle(
                          color: const Color(0xff494949),
                          fontFamily: fontFamily,
                          fontSize: fontSize,
                        ),
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
                      elevation: const MaterialStatePropertyAll(2),
                      controller: search,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    SizedBox(height: size.height * 0.02),
                    // Quick Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        QuickActionButton(
                          size: size,
                          icon: Icons.person_pin_outlined,
                          label: 'Contact',
                          fontSize: fontSize,
                          fontFamily: fontFamily,
                        ),
                        QuickActionButton(
                          size: size,
                          icon: Icons.favorite_outline,
                          label: 'Favourites',
                          fontSize: fontSize,
                          fontFamily: fontFamily,
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.02),
                    // Call List
                    ...['A', 'N', 'L', 'A'].asMap().entries.map((entry) {
                      final names = ['Adil', 'Nadeem', 'Laraib', 'Ahmad'];
                      return Padding(
                        padding: EdgeInsets.only(bottom: size.height * 0.015),
                        child: CallListItem(
                          initial: entry.value,
                          name: names[entry.key],
                          size: size,
                          fontSize: fontSize,
                          fontFamily: fontFamily,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final Size size;
  final IconData icon;
  final String label;
  final double fontSize;
  final String fontFamily;

  const QuickActionButton({
    super.key,
    required this.size,
    required this.icon,
    required this.label,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.height * 0.11,
      width: size.width * 0.28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: const Color(0xffDFF6FF),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xff414141),
            size: size.width * 0.06,
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xff414141),
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CallListItem extends StatelessWidget {
  final String initial;
  final String name;
  final Size size;
  final double fontSize;
  final String fontFamily;

  const CallListItem({
    super.key,
    required this.initial,
    required this.name,
    required this.size,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: size.width * 0.1,
          width: size.width * 0.1,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xff1AB7F4),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize * 1.5,
                fontWeight: FontWeight.w700,
                fontFamily: fontFamily,
              ),
            ),
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: fontFamily,
                  fontSize: fontSize * 1.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.call_received_outlined,
                    color: const Color(0xff04960D),
                    size: fontSize,
                  ),
                  SizedBox(width: size.width * 0.01),
                  Icon(
                    Icons.file_present_outlined,
                    color: const Color(0xff848484),
                    size: fontSize,
                  ),
                  SizedBox(width: size.width * 0.01),
                  Text(
                    '11:15 am',
                    style: TextStyle(
                      color: const Color(0xff848484),
                      fontFamily: fontFamily,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(
          Icons.call,
          size: fontSize * 1.2,
          color: const Color(0xff444444),
        ),
      ],
    );
  }
}
