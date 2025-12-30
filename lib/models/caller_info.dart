class CallerInfo {
  final String? name;
  final bool isSpam;
  final int spamCount;
  final String? provider;
  final String? country;
  final String? numberType;
  final String? photoUrl;
  final double? rating;
  final String? category;
  final List<String>? websites;
  final List<String>? otherNames;

  CallerInfo({
    this.name,
    required this.isSpam,
    this.spamCount = 0,
    this.provider,
    this.country,
    this.numberType,
    this.photoUrl,
    this.rating,
    this.category,
    this.websites,
    this.otherNames,
  });

  // 🔥 Parse Eyecon3 response (for caller info)
  factory CallerInfo.fromEyeconJson(Map<String, dynamic> json) {
    String? callerName = json['fullName'] as String?;
    
    List<String>? otherNames;
    if (json['otherNames'] != null && json['otherNames'] is List) {
      List names = json['otherNames'] as List;
      otherNames = names
          .map((n) => n is Map ? (n['name'] as String?) : n.toString())
          .where((name) => name != null && name.isNotEmpty)
          .cast<String>()
          .toList();
    }
    
    String? photoUrl;
    if (json['images'] != null && json['images'] is List) {
      List images = json['images'] as List;
      if (images.isNotEmpty && images[0]['pictures'] != null) {
        photoUrl = images[0]['pictures']['600'] as String? ??
                   images[0]['pictures']['200'] as String?;
      }
    }
    
    if (photoUrl == null && json['b64'] != null && json['b64'].toString().isNotEmpty) {
      photoUrl = 'data:image/jpeg;base64,${json['b64']}';
    }
    
    // Eyecon doesn't have spam info, so default to false
    return CallerInfo(
      name: callerName ?? json['name'] as String? ?? 'Unknown Number',
      isSpam: false, // Will be overridden by CallerAPI
      spamCount: 0,
      provider: json['provider'] as String?,
      country: json['country'] as String?,
      numberType: otherNames != null && otherNames.isNotEmpty ? 'Multiple Names' : json['numberType'] as String?,
      photoUrl: photoUrl ?? json['photoUrl'] as String?,
      rating: json['rating']?.toDouble(),
      category: json['category'] as String?,
      websites: json['websites'] != null ? List<String>.from(json['websites']) : null,
      otherNames: otherNames,
    );
  }

  // Keep for backward compatibility
  factory CallerInfo.fromJson(Map<String, dynamic> json) {
    return CallerInfo.fromEyeconJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isSpam': isSpam,
      'spamCount': spamCount,
      'provider': provider,
      'country': country,
      'numberType': numberType,
      'photoUrl': photoUrl,
      'rating': rating,
      'category': category,
      'websites': websites,
      'otherNames': otherNames,
    };
  }
}

// SpamCall class stays the same

class SpamCall extends CallerInfo {
  final int? id;
  final String phoneNumber;
  final DateTime timestamp;
  final String callType;
  final String? userId;

  SpamCall({
    this.id,
    this.userId,
    required this.phoneNumber,
    required this.timestamp,
    required this.callType,
    String? name,
    required bool isSpam,
    int spamCount = 0,
    String? provider,
    String? country,
    String? numberType,
    String? photoUrl,
    double? rating,
    String? category,
    List<String>? websites,
    List<String>? otherNames,
  }) : super(
          name: name,
          isSpam: isSpam,
          spamCount: spamCount,
          provider: provider,
          country: country,
          numberType: numberType,
          photoUrl: photoUrl,
          rating: rating,
          category: category,
          websites: websites,
          otherNames: otherNames,
        );

  factory SpamCall.fromMap(Map<String, dynamic> map) {
    return SpamCall(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0'),
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] is int ? map['timestamp'] : int.tryParse(map['timestamp']?.toString() ?? '0') ?? 0
      ),
      callType: map['callType']?.toString() ?? 'incoming',
      name: map['name']?.toString(),
      isSpam: map['isSpam'] == 1 || map['isSpam'] == true,
      spamCount: map['spamCount'] is int ? map['spamCount'] : int.tryParse(map['spamCount']?.toString() ?? '0') ?? 0,
      provider: map['provider']?.toString(),
      country: map['country']?.toString(),
      numberType: map['numberType']?.toString(),
      photoUrl: map['photoUrl']?.toString(),
      rating: map['rating']?.toDouble(),
      category: map['category']?.toString(),
      websites: map['websites'] != null ? List<String>.from(map['websites']) : null,
      otherNames: map['otherNames'] != null ? List<String>.from(map['otherNames']) : null,
      userId: map['userId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'callType': callType,
      'name': name,
      'isSpam': isSpam ? 1 : 0,
      'spamCount': spamCount,
      'provider': provider,
      'country': country,
      'numberType': numberType,
      'photoUrl': photoUrl,
      'rating': rating,
      'category': category,
      'websites': websites,
      'otherNames': otherNames,
      'userId': userId,
    };
  }
}