import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'usage_provider.dart';
import '../models/goal.dart';
import '../models/app_usage.dart';
import '../repositories/firestore_repository.dart';

final goalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  final firestore = ref.watch(firestoreRepositoryProvider);
  return firestore.getGoals(user.uid);
});

// A fully reactive provider that fuses goals with actual daily app usage stats
final dynamicGoalsProvider = Provider<List<Goal>>((ref) {
  final goalsAsync = ref.watch(goalsStreamProvider);
  final usageAsync = ref.watch(dailyUsageProvider);
  
  return goalsAsync.maybeWhen(
    data: (goals) {
      final usage = usageAsync.value ?? [];
      return goals.map((goal) {
        if (goal.category == 'screen_limit') {
          // Look for matching app (e.g. goal: "Limit Instagram", app: "Instagram")
          // Strip out "Limit " prefixes for matching
          final query = goal.title.replaceAll(RegExp(r'Limit\s*', caseSensitive: false), '').trim().toLowerCase();
          
          final matchedApp = usage.firstWhere(
            (app) => app.appName.toLowerCase().contains(query) ||
                     app.packageName.toLowerCase().contains(query),
            orElse: () => AppUsage(
              id: '', 
              userId: '', 
              packageName: '', 
              appName: '', 
              category: AppCategory.neutral, 
              durationMinutes: 0, 
              date: DateTime.now(),
            ),
          );
          
          final currentMin = matchedApp.durationMinutes;
          final isOverLimit = currentMin > goal.targetMinutes;
          final status = isOverLimit 
              ? 'Over limit today' 
              : currentMin == 0 
                  ? 'Not started' 
                  : '${goal.targetMinutes - currentMin}m remaining';
                  
          return goal.copyWith(
            currentMinutes: currentMin,
            status: status,
          );
        }
        return goal;
      }).toList();
    },
    orElse: () => [],
  );
});

final goalsNotifierProvider = StateNotifierProvider<GoalsNotifier, AsyncValue<void>>((ref) {
  return GoalsNotifier(ref.watch(firestoreRepositoryProvider), ref);
});

class GoalsNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreRepository _firestore;
  final Ref _ref;

  GoalsNotifier(this._firestore, this._ref) : super(const AsyncValue.data(null));

  Future<void> addGoal(String title, String emoji, String category, int targetMinutes) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;
    
    state = const AsyncValue.loading();
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final goal = Goal(
        id: id,
        userId: user.uid,
        title: title,
        emoji: emoji,
        category: category,
        targetMinutes: targetMinutes,
        currentMinutes: 0,
        streak: 0,
        status: category == 'screen_limit' ? 'Not started' : '0% complete',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.saveGoal(user.uid, goal);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> incrementGoalProgress(String goalId, int minutes) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final goals = _ref.read(dynamicGoalsProvider);
    final goalIndex = goals.indexWhere((g) => g.id == goalId);
    if (goalIndex == -1) return;

    final goal = goals[goalIndex];
    if (goal.category == 'screen_limit') return; // Handled dynamically by app usage

    final newMinutes = goal.currentMinutes + minutes;
    final isMet = newMinutes >= goal.targetMinutes;
    final percent = goal.targetMinutes > 0 ? (newMinutes / goal.targetMinutes * 100).round() : 100;
    
    int newStreak = goal.streak;
    DateTime? newLastCompleted = goal.lastCompleted;
    if (isMet) {
      final today = DateTime.now();
      final wasCompletedYesterday = goal.lastCompleted != null && 
          DateTime(today.year, today.month, today.day).difference(
            DateTime(goal.lastCompleted!.year, goal.lastCompleted!.month, goal.lastCompleted!.day)
          ).inDays == 1;
      
      newStreak = wasCompletedYesterday ? goal.streak + 1 : 1;
      newLastCompleted = today;
    }

    try {
      await _firestore.updateGoal(user.uid, goalId, {
        'currentMinutes': newMinutes,
        'streak': newStreak,
        'status': isMet ? 'Completed today! 🔥' : '$percent% complete',
        'lastCompleted': newLastCompleted?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Error updating goal progress
    }
  }

  Future<void> deleteGoal(String goalId) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestore.deleteGoal(user.uid, goalId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
