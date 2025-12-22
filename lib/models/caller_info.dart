// models/caller_info.dart
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
  final List<String>? otherNames; // Other names associated with this number

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

  /// ✅ UPDATED: Parse Eyecon3 RapidAPI response (Dec 2025)
  /// Response format:
  /// {
  ///   "status": true,
  ///   "message": "Success",
  ///   "data": {
  ///     "fullName": "Umair Bilal",
  ///     "b64": "base64_photo",
  ///     "otherNames": [{"name": "...", "type": ""}],
  ///     "facebookID": {},
  ///     "images": [{"id": "...", "pictures": {"200": "url", "600": "url"}}]
  ///   }
  /// }
  factory CallerInfo.fromJson(Map<String, dynamic> json) {
    // Extract full name
    String? callerName = json['fullName'] as String?;
    
    // Get other names
    List<String>? otherNames;
    if (json['otherNames'] != null && json['otherNames'] is List) {
      List names = json['otherNames'] as List;
      otherNames = names
          .map((n) => n['name'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .cast<String>()
          .toList();
    }
    
    // Get photo URL from images array
    String? photoUrl;
    if (json['images'] != null && json['images'] is List) {
      List images = json['images'] as List;
      if (images.isNotEmpty && images[0]['pictures'] != null) {
        // Get highest quality image (600px)
        photoUrl = images[0]['pictures']['600'] as String?;
        // Fallback to 200px if 600 not available
        photoUrl ??= images[0]['pictures']['200'] as String?;
      }
    }
    
    // If no image URL, check for base64
    if (photoUrl == null && json['b64'] != null && json['b64'].toString().isNotEmpty) {
      // Store base64 with data URI prefix for easy usage
      photoUrl = 'data:image/jpeg;base64,${json['b64']}';
    }
    
    // Get Facebook ID if available
    String? facebookId;
    if (json['facebookID'] is Map && json['facebookID'].isNotEmpty) {
      facebookId = json['facebookID'].toString();
    }
    
    // Spam detection - Eyecon doesn't provide this directly
    // You can implement custom logic or use another API
    bool isSpam = false;
    int spamCount = 0;

    return CallerInfo(
      name: callerName ?? 'Unknown Number',
      isSpam: isSpam,
      spamCount: spamCount,
      provider: null, // Eyecon doesn't provide carrier info
      country: null,  // Extracted from phone number
      numberType: otherNames != null && otherNames.isNotEmpty ? 'Multiple Names' : null,
      photoUrl: photoUrl,
      rating: null,
      category: facebookId != null ? 'Facebook User' : null,
      websites: null,
      otherNames: otherNames,
    );
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

class SpamCall extends CallerInfo {
  final int? id;
  final String phoneNumber;
  final DateTime timestamp;
  final String callType; // incoming or outgoing
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
      id: map['id'],
      phoneNumber: map['phoneNumber'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      callType: map['callType'],
      name: map['name'],
      isSpam: map['isSpam'] == 1,
      spamCount: map['spamCount'] ?? 0,
      provider: map['provider'],
      country: map['country'],
      numberType: map['numberType'],
      photoUrl: map['photoUrl'],
      rating: map['rating']?.toDouble(),
      category: map['category'],
      websites: map['websites'] != null 
          ? List<String>.from(map['websites']) 
          : null,
      otherNames: map['otherNames'] != null 
          ? List<String>.from(map['otherNames']) 
          : null,
      userId: map['userId'],
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