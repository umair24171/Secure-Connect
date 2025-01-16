// models/caller_info.dart
class CallerInfo {
  final String? name;
  final bool isSpam;
  final int spamCount;
  final String? provider;
  final String? country;
  final String? numberType;

  CallerInfo({
    this.name,
    required this.isSpam,
    this.spamCount = 0,
    this.provider,
    this.country,
    this.numberType,
  });

  factory CallerInfo.fromJson(Map<String, dynamic> json) {
    return CallerInfo(
      name: json['callapp']?['name'] ?? json['eyecon'] ?? 'Unknown Number',
      isSpam: json['callerapi']?['is_spam'] ?? false,
      spamCount: json['callerapi']?['spam_count'] ?? 0,
      provider: json['truecaller']?['provider'],
      country: json['truecaller']?['country'],
      numberType: json['truecaller']?['number_type_label'],
    );
  }
}


class SpamCall extends CallerInfo {
  final int? id;
  final String phoneNumber;
  final DateTime timestamp;
  final String callType; // incoming or outgoing

  SpamCall({
    this.id,
    required this.phoneNumber,
    required this.timestamp,
    required this.callType,
    String? name,
    required bool isSpam,
    int spamCount = 0,
    String? provider,
    String? country,
    String? numberType,
  }) : super(
          name: name,
          isSpam: isSpam,
          spamCount: spamCount,
          provider: provider,
          country: country,
          numberType: numberType,
        );

  factory SpamCall.fromMap(Map<String, dynamic> map) {
    return SpamCall(
      id: map['id'],
      phoneNumber: map['phoneNumber'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      callType: map['callType'],
      name: map['name'],
      isSpam: map['isSpam'] == 1,
      spamCount: map['spamCount'],
      provider: map['provider'],
      country: map['country'],
      numberType: map['numberType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'callType': callType,
      'name': name,
      'isSpam': isSpam ? 1 : 0,  // SQLite doesn't support boolean
      'spamCount': spamCount,
      'provider': provider,
      'country': country,
      'numberType': numberType,
    };
  }
}