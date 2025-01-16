import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:secureconnect/controllers/call_detection_service.dart';
import 'package:secureconnect/controllers/caller_api_service.dart';
import 'package:secureconnect/models/caller_info.dart';


// screens/alert_screen.dart
class AlertScreen extends StatefulWidget {
  final String phoneNumber;
  final CallType callType;
  
  const AlertScreen({
    super.key,
    required this.phoneNumber,
    required this.callType,
  });

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with WidgetsBindingObserver{
 final String fontFamily = 'Roboto';
  final CallerApiService _callerApiService = CallerApiService();
  CallerInfo? _callerInfo;
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchCallerInfo();
    _keepScreenOn();
  }
  
   Future<void> _fetchCallerInfo() async {
    try {
      final info = await _callerApiService.getNumberInfo(widget.phoneNumber);
      if (!_isDisposed) {
        setState(() {
          _callerInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error fetching caller info: $e');
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseScreenLock();
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _keepScreenOn() async {
    try {
      // Keep screen on while alert is showing
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_TURN_SCREEN_ON);
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SHOW_WHEN_LOCKED);
    } catch (e) {
      print('Error setting screen flags: $e');
    }
  }

  Future<void> _releaseScreenLock() async {
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_KEEP_SCREEN_ON);
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_TURN_SCREEN_ON);
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SHOW_WHEN_LOCKED);
    } catch (e) {
      print('Error clearing screen flags: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _keepScreenOn();
    }
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: const Color(0xff66C7F4),
        body: SafeArea(
          child: Container(
            color: const Color(0xff66C7F4),
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.05),
                            Container(
                              height: size.width * 0.2,
                              width: size.width * 0.2,
                              decoration: const BoxDecoration(
                                color: Color(0xffDFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_2_outlined,
                                  size: 55,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _callerInfo?.name ?? 'Unknown Number',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: fontFamily,
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.phoneNumber,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: fontFamily,
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_callerInfo?.provider != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                '${_callerInfo?.provider} - ${_callerInfo?.country}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: fontFamily,
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (_callerInfo?.isSpam == true || _callerInfo?.spamCount != 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.warning_amber,
                                    color: Color(0xffFFB703),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Scam Alert${_callerInfo?.spamCount != 0 ? ' (${_callerInfo?.spamCount} reports)' : ''}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: fontFamily,
                                      fontSize: size.width * 0.045,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                ],
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.1,
                          vertical: size.height * 0.07,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff058B1E),
                                shape: const CircleBorder(),
                                fixedSize: Size(size.width * 0.18, size.width * 0.18),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    elevation: 0,
                                    child: ProceedDialog(
                                      context: context,
                                      size: size,
                                      fontFamily: fontFamily,
                                      phoneNumber: widget.phoneNumber,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox.expand(
                                child: Center(
                                  child: Text(
                                    'Proceed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: fontFamily,
                                      fontSize: size.width * 0.04,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffD20D0D),
                                shape: const CircleBorder(),
                                fixedSize: Size(size.width * 0.18, size.width * 0.18),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: SizedBox.expand(
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: fontFamily,
                                      fontSize: size.width * 0.04,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
      ),
    );
  }
}

// Extract ProceedDialog to a separate widget for better organization
class ProceedDialog extends StatefulWidget {
  final BuildContext context;
  final Size size;
  final String fontFamily;
  final String phoneNumber;

  const ProceedDialog({
    required this.context,
    required this.size,
    required this.fontFamily,
    required this.phoneNumber,
  });

  @override
  State<ProceedDialog> createState() => _ProceedDialogState();
}

class _ProceedDialogState extends State<ProceedDialog> {
  bool? didProceed;
  String? selectedReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size.width * 0.85,
      padding: EdgeInsets.all(widget.size.width * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xffE7F8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            'Did you proceed with call?',
            style: TextStyle(
              color: Colors.black,
              fontFamily: widget.fontFamily,
              fontSize: widget.size.width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: widget.size.height * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionRow(true, widget.size, didProceed == true),
              _buildOptionRow(false, widget.size, didProceed == false),
            ],
          ),
          Divider(
            color: const Color(0xff66C7F4),
            thickness: 0.3,
            height: widget.size.height * 0.03,
          ),
          if (didProceed == true) ...[
            Text(
              'Why did you proceed?',
              style: TextStyle(
                color: Colors.black,
                fontFamily: widget.fontFamily,
                fontSize: widget.size.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: widget.size.height * 0.02),
            ...['Trusted source', 'Mistake', 'Urgent need'].map((option) => 
              InkWell(
                onTap: () => setState(() => selectedReason = option),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: widget.size.height * 0.01),
                  child: Row(
                    children: [
                      Container(
                        height: 30,
                        width: 30,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: selectedReason == option 
                              ? const Color(0xff66C7F4)
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        option,
                        style: TextStyle(
                          color: const Color(0xff5A5A5A),
                          fontFamily: widget.fontFamily,
                          fontSize: widget.size.width * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).toList(),
          ],
          SizedBox(height: widget.size.height * 0.02),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff66C7F4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: Size(0, widget.size.height * 0.045),
                ),
                onPressed: () {
                  // Here you can handle the feedback submission
                  Navigator.pop(context);
                },
                child: Center(
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: widget.fontFamily,
                      fontSize: widget.size.width * 0.04,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(bool isYes, Size size, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => didProceed = isYes),
      child: Row(
        children: [
          Container(
            height: size.width * 0.03,
            width: size.width * 0.03,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff66C7F4) : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: size.width * 0.02),
          Text(
            isYes ? 'Yes' : 'No',
            style: TextStyle(
              color: const Color(0xff5A5A5A),
              fontFamily: widget.fontFamily,
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// class AlertScreen extends StatelessWidget {
//   AlertScreen({super.key});
//   final String fontFamily = 'Roboto';

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: const Color(0xff66C7F4),
//       body: SafeArea(
//         child: Container(
//           color: const Color(0xff66C7F4),
//           width: double.infinity,
//           child: Column(
//             children: [
//               Expanded(
//                 child: Column(
//                   children: [
//                     SizedBox(
//                       height: size.height * 0.05,
//                     ),
//                     Container(
//                       height: size.width * 0.2,
//                       width: size.width * 0.2,
//                       decoration: const BoxDecoration(
//                         color: Color(0xffDFF6FF),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Center(
//                         child: Icon(
//                           Icons.person_2_outlined,
//                           size: 55,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       'Unknown Number',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontFamily: fontFamily,
//                         fontSize: size.width * 0.05,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '+923165018758',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontFamily: fontFamily,
//                         fontSize: size.width * 0.045,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.warning_amber,
//                           color: Color(0xffFFB703),
//                           size: 24,
//                         ),
//                         const SizedBox(width: 5),
//                         Text(
//                           'Scam Alert',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontFamily: fontFamily,
//                             fontSize: size.width * 0.045,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         )
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: size.width * 0.1,
//                   vertical: size.height * 0.07,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xff058B1E),
//                         shape: const CircleBorder(),
//                         fixedSize: Size(size.width * 0.18, size.width * 0.18),
//                         padding: EdgeInsets.zero, // Remove default padding
//                       ),
//                       onPressed: () {
//                         showDialog(
//                           context: context,
//                           builder: (context) => Dialog(
//                             elevation: 0, // Remove elevation
//                             child: Proceed(context),
//                           ),
//                         );
//                       },
//                       child: SizedBox.expand(
//                         // Make child expand to fill button
//                         child: Center(
//                           child: Text(
//                             'Proceed',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontFamily: fontFamily,
//                               fontSize: size.width * 0.04,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xffD20D0D),
//                         shape: const CircleBorder(),
//                         fixedSize: Size(size.width * 0.18, size.width * 0.18),
//                         padding: EdgeInsets.zero, // Remove default padding
//                       ),
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       child: SizedBox.expand(
//                         // Make child expand to fill button
//                         child: Center(
//                           child: Text(
//                             'Cancel',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontFamily: fontFamily,
//                               fontSize: size.width * 0.04,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget Proceed(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Container(
//       width: size.width * 0.85,
//       padding: EdgeInsets.all(size.width * 0.04),
//       decoration: BoxDecoration(
//           color: const Color(0xffE7F8FF),
//           borderRadius: BorderRadius.circular(16)),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),
//           Text(
//             'Did you proceed with call?',
//             style: TextStyle(
//                 color: Colors.black,
//                 fontFamily: fontFamily,
//                 fontSize: size.width * 0.04,
//                 fontWeight: FontWeight.w500),
//           ),
//           SizedBox(height: size.height * 0.02),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildOptionRow(true, size),
//               _buildOptionRow(false, size),
//             ],
//           ),
//           Divider(
//             color: const Color(0xff66C7F4),
//             thickness: 0.3,
//             height: size.height * 0.03,
//           ),
//           Text(
//             'Why did u proceed?',
//             style: TextStyle(
//                 color: Colors.black,
//                 fontFamily: fontFamily,
//                 fontSize: size.width * 0.04,
//                 fontWeight: FontWeight.w500),
//           ),
//           SizedBox(height: size.height * 0.02),
//           ...['Trusted source', 'Mistake', 'Urgent need']
//               .map((option) => Padding(
//                     padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
//                     child: Row(
//                       children: [
//                         Container(
//                           height: 30,
//                           width: 30, // Added width
//                           margin: EdgeInsets.only(right: 10), // Added margin
//                           decoration: const BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                         Text(
//                           option,
//                           style: TextStyle(
//                               color: const Color(0xff5A5A5A),
//                               fontFamily: fontFamily,
//                               fontSize: size.width * 0.04,
//                               fontWeight: FontWeight.w600),
//                         ),
//                       ],
//                     ),
//                   ))
//               .toList(), // Added toList()
//           SizedBox(height: size.height * 0.02),
//           Align(
//             alignment: Alignment.centerRight,
//             child: SizedBox(
//               // Wrap with SizedBox to constrain width
//               width: 120, // Adjust this value to your desired width
//               child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xff66C7F4),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20)),
//                     minimumSize: Size(0,
//                         size.height * 0.045), // Changed from 150 to 0 for width
//                   ),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: Center(
//                     child: Text(
//                       'Proceed',
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontFamily: fontFamily,
//                           fontSize: size.width * 0.04,
//                           fontWeight: FontWeight.w700),
//                     ),
//                   )),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildOptionRow(bool isYes, Size size) {
//     return Row(
//       children: [
//         Container(
//           height: size.width * 0.03,
//           width: size.width * 0.03,
//           decoration: BoxDecoration(
//               color: isYes ? const Color(0xff66C7F4) : Colors.white,
//               shape: BoxShape.circle),
//         ),
//         SizedBox(width: size.width * 0.02),
//         Text(
//           isYes ? 'Yes' : 'No',
//           style: TextStyle(
//               color: const Color(0xff5A5A5A),
//               fontFamily: fontFamily,
//               fontSize: size.width * 0.04,
//               fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }
// }
