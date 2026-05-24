import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import 'auth_provider.dart';

import '../services/domain_achievements_service.dart';

final achievementsProvider = StreamProvider<List<Achievement>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield [];
    return;
  }
  
  final firestore = ref.watch(firestoreRepositoryProvider);
  
  await for (final firestoreAchievements in firestore.getAchievements(user.uid)) {
    final profile = await ref.read(userProfileProvider.future);
    final dynamicAchievements = profile != null 
        ? DomainAchievementsService.getAchievementsForInterests(profile.interests) 
        : <Achievement>[];
        
    final existingIds = firestoreAchievements.map((a) => a.id).toSet();
    final combined = List<Achievement>.from(firestoreAchievements);
    
    for (var dyn in dynamicAchievements) {
      if (!existingIds.contains(dyn.id)) {
        combined.add(dyn);
      }
    }
    
    yield combined;
  }
});

final xpProgressProvider = Provider<double>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile == null) return 0.0;
      
      final currentLevel = profile.level;
      
      // Calculate the cumulative XP required to enter the current level
      // Level 1 starts at 0 XP
      // Level 2 starts at 100 XP
      // Level 3 starts at 100 + 200 = 300 XP, etc.
      int startXpOfCurrentLevel = 0;
      for (int i = 1; i < currentLevel; i++) {
        startXpOfCurrentLevel += 100 * i;
      }
      
      final xpInCurrentLevel = profile.xpPoints - startXpOfCurrentLevel;
      final xpNeededForNextLevel = 100 * currentLevel;
      
      return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
    },
    orElse: () => 0.0,
  );
});
