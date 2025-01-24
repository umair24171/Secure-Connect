import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountDeletionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> deleteUserAccount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Delete user's spam calls
      await _firestore
          .collection('spam_calls')
          .where('userId', isEqualTo: currentUser.uid)
          .get()
          .then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Delete user's blocked contacts
      await _firestore
          .collection('blocked_contacts')
          .where('userId', isEqualTo: currentUser.uid)
          .get()
          .then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Delete user document from users collection
      await _firestore.collection('users').doc(currentUser.uid).delete();

      // Delete the user account
      await currentUser.delete();

      return true;
    } catch (e) {
      print('Account deletion error: $e');
      return false;
    }
  }
}