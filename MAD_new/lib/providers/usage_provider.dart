import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_usage.dart';
import 'auth_provider.dart';
import '../services/usage_tracking_service.dart';
import 'focus_provider.dart';
import 'goals_provider.dart';
import 'achievements_provider.dart';

final usageTrackingServiceProvider = Provider<UsageTrackingService>((ref) {
  return UsageTrackingService(ref.watch(firestoreRepositoryProvider));
});

final dailyUsageProvider = StreamProvider<List<AppUsage>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  
  final firestore = ref.watch(firestoreRepositoryProvider);
  return firestore.getDailyUsage(user.uid, DateTime.now());
});

final productivityScoreProvider = Provider<double>((ref) {
  final usageAsync = ref.watch(dailyUsageProvider);
  final goals = ref.watch(dynamicGoalsProvider);
  final achievementsAsync = ref.watch(achievementsProvider);
  final focusTimer = ref.watch(focusTimerProvider);

  double baseRatio = 0.0;
  
  if (usageAsync.value != null && usageAsync.value!.isNotEmpty) {
      final usage = usageAsync.value!;
      int productiveMinutes = 0;
      int distractingMinutes = 0;
      
      for (var app in usage) {
        if (app.category == AppCategory.productive) {
          productiveMinutes += app.durationMinutes;
        } else if (app.category == AppCategory.distracting) {
          distractingMinutes += app.durationMinutes;
        }
      }
      
      final totalBase = productiveMinutes + distractingMinutes;
      if (totalBase > 0) {
         baseRatio = (productiveMinutes / totalBase).clamp(0.0, 1.0);
      } else {
         baseRatio = 0.5; // neutral if no strict productive/distracting
      }
  }

  double goalsRatio = 0.0;
  if (goals.isNotEmpty) {
     double totalProgress = 0.0;
     for (var g in goals) {
        totalProgress += g.progress.clamp(0.0, 1.0);
     }
     goalsRatio = totalProgress / goals.length;
  }

  double streaksRatio = 0.0;
  if (achievementsAsync.value != null) {
      final unlocked = achievementsAsync.value!.where((a) => a.isUnlocked).length;
      streaksRatio = (unlocked / 10).clamp(0.0, 1.0); // simple mapping
  }

  double focusRatio = 0.0;
  if (focusTimer.isCompleted) {
      focusRatio = 1.0;
  } else if (focusTimer.isRunning) {
      focusRatio = focusTimer.progress;
  }

  // Weights: 40% base usage, 30% goals, 20% focus, 10% streaks/achievements
  double finalScore = (baseRatio * 0.4) + (goalsRatio * 0.3) + (focusRatio * 0.2) + (streaksRatio * 0.1);
  return finalScore.clamp(0.0, 1.0);
});

final socialTimeProvider = Provider<int>((ref) {
  final usageAsync = ref.watch(dailyUsageProvider);
  return usageAsync.maybeWhen(
    data: (usage) {
      return usage
          .where((app) => app.category == AppCategory.distracting)
          .fold(0, (sum, app) => sum + app.durationMinutes);
    },
    orElse: () => 0,
  );
});
