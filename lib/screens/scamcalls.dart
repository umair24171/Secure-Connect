import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secureconnect/controllers/spam_call_service.dart';
import 'package:secureconnect/models/caller_info.dart';

class Scamcalls extends StatefulWidget {
  const Scamcalls({super.key});

  @override
  State<Scamcalls> createState() => _ScamcallsState();
}

class _ScamcallsState extends State<Scamcalls> {
 final String fontFamily = 'Roboto';
  final TextEditingController search = TextEditingController();
  final ScamCallsService _scamCallsService = ScamCallsService();
  String searchQuery = '';
  List<SpamCall> spamCalls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _scamCallsService.initialize();
    _loadSpamCalls();
  }

  Future<void> _loadSpamCalls() async {
    setState(() => isLoading = true);
    final calls = await _scamCallsService.getSpamCalls(searchQuery: searchQuery);
    setState(() {
      spamCalls = calls;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final size = MediaQuery.of(context).size;

    // Calculate responsive values
    final double paddingScale = size.width * 0.04;
    final double iconSize = size.width * 0.06;
    final double fontSize = size.width * 0.04;
    final double smallFontSize = size.width * 0.035;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: size.height * 0.1,
        backgroundColor: Color(0xff66C7F4),
        leading: Container(
          margin: EdgeInsets.only(left: 10),
          height: size.height * 0.04,
          width: size.height * 0.04,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xffDFF6FF),
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: size.height * 0.03,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Scam Calls',
          style: TextStyle(
            color: Colors.white,
            fontFamily: fontFamily,
            fontSize: size.width * 0.058,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xffffffff),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(13),
            topRight: Radius.circular(13),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: paddingScale,
            vertical: paddingScale * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                shadowColor: const MaterialStatePropertyAll(Color(0xffDFF6FF)),
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
              Text(
                'Scam Numbers',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: size.height * 0.015),
               Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: spamCalls.length,
                        itemBuilder: (context, index) {
                          final call = spamCalls[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: size.height * 0.01),
                            child: ScamCallContainer(
  size: size,
  fontSize: fontSize,
  smallFontSize: smallFontSize,
  fontFamily: fontFamily,
  spamCall: call,
  onIgnore: () async {
    // Handle ignore action
    await _scamCallsService.deleteSpamCall(call.id!);
    _loadSpamCalls();
  },
  onReport: () async {
    // Handle report action
    // You might want to show a confirmation dialog here
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Spam'),
        content: Text('Do you want to report this number as spam?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Report the number
              Navigator.pop(context);
            },
            child: Text('Report'),
          ),
        ],
      ),
    );
  },
),
                          );
                        },
                      ),
              ),
              // Expanded(
              //   child: ListView.builder(
              //     itemCount: 3, // Replace with actual data length
              //     itemBuilder: (context, index) {
              //       return Padding(
              //         padding: EdgeInsets.only(bottom: size.height * 0.01),
              //         child: ScamCallContainer(
              //           size: size,
              //           fontSize: fontSize,
              //           smallFontSize: smallFontSize,
              //           fontFamily: fontFamily,
              //         ),
              //       );
              //     },
              //   ),
              // ),
            
            ],
          ),
        ),
      ),
    );
  }
}


class ScamCallContainer extends StatelessWidget {
  final Size size;
  final double fontSize;
  final double smallFontSize;
  final String fontFamily;
  final SpamCall spamCall;
  final VoidCallback? onIgnore;
  final VoidCallback? onReport;

  const ScamCallContainer({
    super.key,
    required this.size,
    required this.fontSize,
    required this.smallFontSize,
    required this.fontFamily,
    required this.spamCall,
    this.onIgnore,
    this.onReport,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (date == today) {
      return DateFormat('hh:mm a').format(timestamp);
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('hh:mm a').format(timestamp)}';
    } else {
      return DateFormat('MMM dd, hh:mm a').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.015,
        horizontal: size.width * 0.04,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffDFF6FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: const Color(0xffFFB703),
                  size: size.width * 0.06,
                ),
                SizedBox(width: size.width * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spamCall.name ?? 'Unknown Number',
                        style: TextStyle(
                          color: const Color(0xff393939),
                          fontFamily: fontFamily,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        spamCall.phoneNumber,
                        style: TextStyle(
                          color: const Color(0xff393939),
                          fontFamily: fontFamily,
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatTimestamp(spamCall.timestamp),
                            style: TextStyle(
                              color: const Color(0xff848484),
                              fontFamily: fontFamily,
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (spamCall.spamCount > 0) ...[
                            Text(
                              ' • ${spamCall.spamCount} reports',
                              style: TextStyle(
                                color: const Color(0xffD20D0D),
                                fontFamily: fontFamily,
                                fontSize: smallFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (spamCall.provider != null && spamCall.country != null)
                        Text(
                          '${spamCall.provider} • ${spamCall.country}',
                          style: TextStyle(
                            color: const Color(0xff848484),
                            fontFamily: fontFamily,
                            fontSize: smallFontSize,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onIgnore,
                child: Text(
                  'Ignore',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: fontFamily,
                    fontSize: smallFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.02),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: size.height * 0.01,
                    horizontal: size.width * 0.03,
                  ),
                  backgroundColor: const Color(0xffD20D0D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: onReport,
                child: Text(
                  'Report',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: smallFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xffffffff),
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