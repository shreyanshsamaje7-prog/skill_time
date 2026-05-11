import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import 'auth_provider.dart';

final achievementsProvider = StreamProvider<List<Achievement>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  
  final firestore = ref.watch(firestoreRepositoryProvider);
  return firestore.getAchievements(user.uid);
});

final xpProgressProvider = Provider<double>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile == null) return 0.0;
      // Calculate progress to next level based on current xp
      // Let's assume each level requires 100 * level XP
      final currentLevel = profile.level;
      final xpForNextLevel = 100 * currentLevel;
      final currentLevelXp = profile.xpPoints % xpForNextLevel;
      
      return (currentLevelXp / xpForNextLevel).clamp(0.0, 1.0);
    },
    orElse: () => 0.0,
  );
});
