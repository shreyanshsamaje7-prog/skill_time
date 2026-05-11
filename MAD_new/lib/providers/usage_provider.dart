import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_usage.dart';
import 'auth_provider.dart';
import '../services/usage_tracking_service.dart';

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
  
  return usageAsync.when(
    data: (usage) {
      if (usage.isEmpty) return 0.0;
      
      int totalMinutes = 0;
      int productiveMinutes = 0;
      
      for (var app in usage) {
        totalMinutes += app.durationMinutes;
        if (app.category == AppCategory.productive) {
          productiveMinutes += app.durationMinutes;
        } else if (app.category == AppCategory.distracting) {
          productiveMinutes -= (app.durationMinutes * 0.5).round();
        }
      }
      
      if (totalMinutes == 0) return 0.0;
      
      double score = (productiveMinutes / totalMinutes).clamp(0.0, 1.0);
      return score;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
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
