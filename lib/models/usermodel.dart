class userModel {
  String userId;
  String userName;
  String userEmail;
  String userPass;
  String userPhoneNumber;
  String age;

  userModel(
      {required this.userId,
      required this.userName,
      required this.userEmail,
      required this.userPass,
      required this.age,
      required this.userPhoneNumber});

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPass': userPass,
      'age': age,
      'userPhoneNumber': userPhoneNumber
    };
  }

  factory userModel.fromMap(Map<String, dynamic> map) {
    return userModel(
        userId: map['userId'],
        userName: map['userName'],
        userEmail: map['userEmail'],
        userPass: map['userPass'],
        age: map['age'],
        userPhoneNumber: map['userPhoneNumber']);
  }
}
