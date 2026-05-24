import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/app_usage.dart';
import '../models/achievement.dart';
import '../models/goal.dart';
import '../models/focus_session.dart';

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

  Future<void> completeOnboarding(String userId, List<String> interests) async {
    await _firestore.collection('users').doc(userId).update({
      'interests': interests,
      'onboardingCompleted': true,
    });
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

  Stream<List<AppUsage>> getUsageInRange(String userId, DateTime start, DateTime end) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('usage')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUsage.fromJson(doc.data(), doc.id)).toList();
    });
  }

  // --- Goals ---
  Stream<List<Goal>> getGoals(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Goal.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> saveGoal(String userId, Goal goal) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goal.id)
        .set(goal.toJson());
  }

  Future<void> updateGoal(String userId, String goalId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .update(data);
  }

  Future<void> deleteGoal(String userId, String goalId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

  // --- Focus Sessions ---
  Stream<List<FocusSession>> getFocusSessions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('focus_sessions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FocusSession.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> saveFocusSession(String userId, FocusSession session) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('focus_sessions')
        .doc(session.id)
        .set(session.toJson());
  }

  // --- Achievements ---
  Stream<List<Achievement>> getAchievements(String userId) {
    final ref = _firestore.collection('users').doc(userId).collection('achievements');
    return ref.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        _initializeDefaultAchievements(userId);
        return [];
      }
      return snapshot.docs.map((doc) => Achievement.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> _initializeDefaultAchievements(String userId) async {
    final ref = _firestore.collection('users').doc(userId).collection('achievements');
    final batch = _firestore.batch();
    
    final defaults = [
      Achievement(
        id: 'goal_completed_1',
        title: 'First Goal Completed!',
        description: 'Complete 1 daily goal',
        icon: '🎯',
        xpReward: 100,
      ),
      Achievement(
        id: 'productivity_master',
        title: 'Productivity Master',
        description: 'Earn a score above 85%',
        icon: '⚡',
        xpReward: 150,
      ),
      Achievement(
        id: 'focus_fanatic',
        title: 'Focus Fanatic',
        description: 'Complete your first Focus session',
        icon: '🧠',
        xpReward: 200,
      ),
      Achievement(
        id: 'streak_starter',
        title: 'Streak Starter',
        description: 'Maintain a 3-day goal streak',
        icon: '🔥',
        xpReward: 100,
      ),
      Achievement(
        id: 'social_fast',
        title: 'Social Fast',
        description: 'Keep daily social time under 30 mins',
        icon: '🚫',
        xpReward: 120,
      ),
    ];

    for (var item in defaults) {
      batch.set(ref.doc(item.id), item.toJson());
    }
    await batch.commit();
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    await _firestore.collection('users').doc(userId).collection('achievements').doc(achievementId).update({
      'isUnlocked': true,
      'unlockedAt': DateTime.now().toIso8601String(),
    });
  }
}
