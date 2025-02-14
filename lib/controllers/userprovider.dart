import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secureconnect/models/usermodel.dart';
import 'package:secureconnect/screens/home.dart';
import 'package:secureconnect/screens/login.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

 bool _isPassVisible=false;

 bool get isPassVisible=>_isPassVisible;


 setIsPassValue(bool value){
  _isPassVisible=value;
  notifyListeners();

 }

  Future<bool> signup({
    required String email,
    required String password,
    required String userName,
    required String phoneNumber,
    required String age,
    required BuildContext context,
  }) async {
    if (!_validateInputs(email, password, userName, phoneNumber)) {
      _errorMessage = "Please fill in all fields";
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user model
        userModel newUser = userModel(
          userId: userCredential.user!.uid,
          userName: userName,
          userEmail: email,
          userPass: password,
          age: age,
          userPhoneNumber: phoneNumber,
        );

        // Save user data to Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());

        _isLoading = false;
        notifyListeners();

        // Navigate to login page on success
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    if (!_validateInputs(email, password)) {
      _errorMessage = "Please fill in all fields";
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();

      if (userCredential.user != null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool _validateInputs(String email, String password,
      [String? userName, String? phoneNumber]) {
    if (userName != null && phoneNumber != null) {
      return email.isNotEmpty &&
          password.isNotEmpty &&
          userName.isNotEmpty &&
          phoneNumber.isNotEmpty;
    }
    return email.isNotEmpty && password.isNotEmpty;
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    _isLoading = false;
    switch (e.code) {
      case 'weak-password':
        _errorMessage = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        _errorMessage = 'An account already exists for that email.';
        break;
      case 'invalid-email':
        _errorMessage = 'Please provide a valid email address.';
        break;
      case 'user-not-found':
        _errorMessage = 'No user found for that email.';
        break;
      case 'wrong-password':
        _errorMessage = 'Wrong password provided.';
        break;
      default:
        _errorMessage = 'Authentication error: ${e.message}';
    }
    notifyListeners();
  }
}
