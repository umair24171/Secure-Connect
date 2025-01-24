import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/caller_info.dart';

class ScamCallsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Any initialization if needed
  }

  Future<List<SpamCall>> getSpamCalls({String searchQuery = ''}) async {
    try {
      Query query = _firestore.collection('spam_calls');

      // Apply search filter if searchQuery is not empty
      if (searchQuery.isNotEmpty) {
        query = query.where('phoneNumber', isGreaterThanOrEqualTo: searchQuery)
                    .where('phoneNumber', isLessThanOrEqualTo: searchQuery + '\uf8ff');
      }

      // Order by timestamp, most recent first
      query = query.orderBy('timestamp', descending: true);

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add Firestore document ID
        return SpamCall.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching spam calls: $e');
      return [];
    }
  }

  Future<void> deleteSpamCall(String id) async {
    try {
      await _firestore.collection('spam_calls').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting spam call: $e');
    }
  }

  Future<void> reportSpamCall(SpamCall spamCall) async {
    try {
      // Increment spam count or add additional reporting logic
      await _firestore.collection('spam_calls').doc(spamCall.phoneNumber).update({
        'spamCount': FieldValue.increment(1),
        // Add any additional reporting metadata
      });
    } catch (e) {
      debugPrint('Error reporting spam call: $e');
    }
  }
}