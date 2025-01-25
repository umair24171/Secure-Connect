import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class CallLogsScreen extends StatefulWidget {
  final String callType;
  
  const CallLogsScreen({
    super.key,
    required this.callType,
  });

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  final String fontFamily = 'Roboto';
  final TextEditingController search = TextEditingController();
  String searchQuery = '';

  List<CallLogEntry> _callLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCallLogs();
  }

  Future<void> _getCallLogs() async {
    final status = await Permission.phone.request();
    
    if (status.isGranted) {
      final CallLogs = await CallLog.get();
      setState(() {
        _callLogs = CallLogs.toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied to access call logs'),
          ),
        );
      }
    }
  }

  List<CallLogEntry> _getFilteredCallLogs() {
    if (searchQuery.isEmpty) {
      return _callLogs.where(_matchesCallType).toList();
    }
    return _callLogs
        .where(_matchesCallType)
        .where((call) {
          final name = call.name?.toLowerCase() ?? '';
          final number = call.number?.toLowerCase() ?? '';
          return name.contains(searchQuery.toLowerCase()) || 
                 number.contains(searchQuery.toLowerCase());
        })
        .toList();
  }

  bool _matchesCallType(CallLogEntry call) {
    switch (widget.callType.toLowerCase()) {
      case 'outgoing':
        return call.callType == CallType.outgoing;
      case 'incoming':
        return call.callType == CallType.incoming;
      case 'missed':
        return call.callType == CallType.missed;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double paddingScale = size.width * 0.04;
    final double fontSize = size.width * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Column(
        children: [
          // Top App Bar with Blue Background
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
                  Center(
                    child: Text(
                      '${widget.callType.capitalize()} Calls',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: fontFamily,
                        fontSize: fontSize * 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
                          size: size.width * 0.05,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
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
                            hintText: 'Search calls',
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
                                searchQuery = value;
                              });
                            },
                          ),
                          SizedBox(height: size.height * 0.02),
                          
                          // Call Logs List
                          ..._getFilteredCallLogs().map((call) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: size.height * 0.015),
                              child: CallLogListItem(
                                call: call,
                                size: size,
                                fontSize: fontSize,
                                fontFamily: fontFamily,
                              ),
                            );
                          }).toList(),

                          // Empty state
                          if (_getFilteredCallLogs().isEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: size.height * 0.1),
                              child: Text(
                                'No ${widget.callType} calls found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: fontFamily,
                                  fontSize: fontSize,
                                ),
                              ),
                            ),
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

class CallLogListItem extends StatelessWidget {
  final CallLogEntry call;
  final Size size;
  final double fontSize;
  final String fontFamily;

  const CallLogListItem({
    super.key,
    required this.call,
    required this.size,
    required this.fontSize,
    required this.fontFamily,
  });

  String _formatDateTime(int? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(dateTime);
  }

  IconData _getCallIcon(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return Icons.call_received_outlined;
      case CallType.outgoing:
        return Icons.call_made_outlined;
      case CallType.missed:
        return Icons.call_missed_outgoing_outlined;
      default:
        return Icons.call_outlined;
    }
  }

  Color _getCallIconColor(CallType? callType) {
    switch (callType) {
      case CallType.missed:
        return Colors.red;
      case CallType.incoming:
        return const Color(0xff04960D);
      case CallType.outgoing:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

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
              (call.name ?? 'U')[0],
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
                call.name ?? 'Unknown',
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
                    _getCallIcon(call.callType),
                    color: _getCallIconColor(call.callType),
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
                    _formatDateTime(call.timestamp),
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
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}