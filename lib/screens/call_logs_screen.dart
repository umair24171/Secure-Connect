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
  List<CallLogEntry> _callLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCallLogs();
  }

  Future<void> _getCallLogs() async {
    // Request phone permission
    final status = await Permission.phone.request();
    
    if (status.isGranted) {
      // Get call logs
      final CallLogs = await CallLog.get();
      setState(() {
        _callLogs = CallLogs.toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // Show permission denied message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied to access call logs'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.callType.capitalize()} Calls',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xff66C7F4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _callLogs.isEmpty
              ? const Center(child: Text('No call logs found'))
              : ListView.builder(
                  itemCount: _callLogs.length,
                  itemBuilder: (context, index) {
                    final call = _callLogs[index];
                    if (_matchesCallType(call.callType)) {
                      return CallLogTile(call: call, size: size);
                    }
                    return const SizedBox.shrink();
                  },
                ),
    );
  }

  bool _matchesCallType(CallType? callType) {
    switch (widget.callType.toLowerCase()) {
      case 'outgoing':
        return callType == CallType.outgoing;
      case 'incoming':
        return callType == CallType.incoming;
      case 'missed':
        return callType == CallType.missed;
      default:
        return false;
    }
  }
}

class CallLogTile extends StatelessWidget {
  final CallLogEntry call;
  final Size size;

  const CallLogTile({
    super.key,
    required this.call,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.01,
      ),
      padding: EdgeInsets.all(size.width * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xffDFF6FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(size.width * 0.02),
            decoration: BoxDecoration(
              color: _getCallTypeColor(),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCallTypeIcon(),
              color: Colors.white,
              size: size.width * 0.05,
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
                    fontFamily: 'Roboto',
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                  call.number ?? 'No number',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: size.width * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDateTime(call.timestamp),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: size.width * 0.035,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: size.height * 0.005),
              Text(
                _formatDuration(call.duration ?? 0),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: size.width * 0.035,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCallTypeColor() {
    switch (call.callType) {
      case CallType.outgoing:
        return Colors.green;
      case CallType.incoming:
        return Colors.blue;
      case CallType.missed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCallTypeIcon() {
    switch (call.callType) {
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.incoming:
        return Icons.call_received;
      case CallType.missed:
        return Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  String _formatDateTime(int? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    if (dateTime.isAfter(today)) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (dateTime.isAfter(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}