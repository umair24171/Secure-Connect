import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  FeedbackScreen({super.key});
  final String fontFamily = 'Roboto';

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final size = MediaQuery.of(context).size;
    // Calculate responsive values
    final double paddingScale = size.width * 0.04;
    final double fontSize = size.width * 0.04;
    final double headerFontSize = size.width * 0.05;
    final double iconSize = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xff66C7F4),
      body: SafeArea(
        child: Container(
          color: const Color(0xff66C7F4),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: paddingScale,
                  vertical: paddingScale * 0.6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Add this
                  children: [
                    Container(
                      height: iconSize * 1.6,
                      width: iconSize * 1.6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xffDFF6FF),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: iconSize,
                        ),
                      ),
                    ),
                    SizedBox(width: paddingScale),
                    Expanded(
                      child: Text(
                        'Post call feedback',
                        textAlign: TextAlign.center, // Add this
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: fontFamily,
                          fontSize: headerFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    color: const Color(
                      0xffDFF6FF,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(paddingScale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuestion(
                              'Did you proceed with the call to the flagged number?',
                              fontSize,
                            ),
                            SizedBox(height: paddingScale),
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .end, // This will align items to the right
                              children: [
                                _buildOptionRow(true, size, fontSize),
                                SizedBox(
                                  width: size.height * 0.03,
                                ),
                                _buildOptionRow(false, size, fontSize),
                              ],
                            ),
                            _buildDivider(),
                            _buildQuestion(
                              "Did you recognize the caller's number before receiving the scam alert?",
                              fontSize,
                            ),
                            SizedBox(height: paddingScale),
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .end, // This will align items to the right
                              children: [
                                _buildOptionRow(true, size, fontSize),
                                SizedBox(
                                  width: size.height * 0.03,
                                ),
                                _buildOptionRow(false, size, fontSize),
                              ],
                            ),
                            _buildDivider(),
                            _buildQuestion(
                              "How would you rate the accuracy of the scam alert for this call?",
                              fontSize,
                            ),
                            SizedBox(height: paddingScale),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: size.width * 0.01,
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: size.width * 0.02,
                                ),
                                overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: size.width * 0.04,
                                ),
                                activeTrackColor: const Color(0xff1FAAEA),
                                inactiveTrackColor: const Color(0xffD9D9D9),
                                thumbColor: const Color(0xff1FAAEA),
                                overlayColor:
                                    const Color(0xff1FAAEA).withOpacity(0.2),
                              ),
                              child: Slider(
                                min: 0,
                                max: 100,
                                value: 50,
                                onChanged: (value) {},
                              ),
                            ),
                            _buildDivider(),
                            _buildQuestion(
                              "Was the warning message easy to understand?",
                              fontSize,
                            ),
                            SizedBox(height: paddingScale),
                            _buildCheckboxOption('Trusted source', fontSize),
                            _buildCheckboxOption('Mistake', fontSize),
                            _buildCheckboxOption('Urgent need', fontSize),
                            SizedBox(height: paddingScale * 1.5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Skip',
                                    style: TextStyle(
                                      color: const Color(0xff1FAAEA),
                                      fontFamily: fontFamily,
                                      fontSize: fontSize * 1.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff66C7F4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 30)),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Center(
                                    child: Text(
                                      'Submit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: fontFamily,
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: paddingScale),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(String text, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.black,
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildOptionRow(bool isYes, Size size, double fontSize) {
    return Row(
      children: [
        Container(
          height: size.width * 0.04,
          width: size.width * 0.04,
          decoration: BoxDecoration(
            color: isYes ? const Color(0xff66C7F4) : Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: size.width * 0.02),
        Text(
          isYes ? 'Yes' : 'No',
          style: TextStyle(
            color: const Color(0xff5A5A5A),
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            height: 20,
            width: 20,
            decoration:
                BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: const Color(0xff424242),
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(
        color: Color(0xff66C7F4),
        thickness: 0.3,
      ),
    );
  }
}
