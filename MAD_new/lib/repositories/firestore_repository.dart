import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/app_usage.dart';
import '../models/achievement.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Users ---
  Future<void> createUserProfile(UserProfile user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Stream<UserProfile?> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromJson(snapshot.data()!, snapshot.id);
    });
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // --- App Usage ---
  Future<void> saveAppUsage(String userId, List<AppUsage> usageRecords) async {
    final batch = _firestore.batch();
    for (var record in usageRecords) {
      final docRef = _firestore.collection('users').doc(userId).collection('usage').doc(record.id);
      batch.set(docRef, record.toJson());
    }
    await batch.commit();
  }

  Stream<List<AppUsage>> getDailyUsage(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('usage')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUsage.fromJson(doc.data(), doc.id)).toList();
    });
  }

  // --- Achievements ---
  Stream<List<Achievement>> getAchievements(String userId) {
    return _firestore.collection('users').doc(userId).collection('achievements').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Achievement.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    await _firestore.collection('users').doc(userId).collection('achievements').doc(achievementId).update({
      'isUnlocked': true,
      'unlockedAt': DateTime.now().toIso8601String(),
    });
  }
}

  
