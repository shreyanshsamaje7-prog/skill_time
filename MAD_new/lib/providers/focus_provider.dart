import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'goals_provider.dart';
import '../models/focus_session.dart';

class FocusTimerState {
  final int totalSeconds;
  final int secondsRemaining;
  final bool isRunning;
  final String selectedSkill;
  final bool isCompleted;

  FocusTimerState({
    required this.totalSeconds,
    required this.secondsRemaining,
    required this.isRunning,
    required this.selectedSkill,
    required this.isCompleted,
  });

  double get progress => totalSeconds == 0 ? 0.0 : (totalSeconds - secondsRemaining) / totalSeconds;
  String get timeString {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  FocusTimerState copyWith({
    int? totalSeconds,
    int? secondsRemaining,
    bool? isRunning,
    String? selectedSkill,
    bool? isCompleted,
  }) {
    return FocusTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRunning: isRunning ?? this.isRunning,
      selectedSkill: selectedSkill ?? this.selectedSkill,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

final focusTimerProvider = StateNotifierProvider<FocusTimerNotifier, FocusTimerState>((ref) {
  return FocusTimerNotifier(ref);
});

class FocusTimerNotifier extends StateNotifier<FocusTimerState> {
  final Ref _ref;
  Timer? _timer;

  FocusTimerNotifier(this._ref)
      : super(FocusTimerState(
          totalSeconds: 1500, // 25 minutes default
          secondsRemaining: 1500,
          isRunning: false,
          selectedSkill: 'Coding',
          isCompleted: false,
        ));

  void setDuration(int minutes) {
    if (state.isRunning) return;
    final seconds = minutes * 60;
    state = state.copyWith(
      totalSeconds: seconds,
      secondsRemaining: seconds,
      isCompleted: false,
    );
  }

  void setSelectedSkill(String skill) {
    state = state.copyWith(selectedSkill: skill);
  }

  void startTimer() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, isCompleted: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining <= 1) {
        _completeSession();
      } else {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resetTimer() {
    _timer?.cancel();
    state = state.copyWith(
      secondsRemaining: state.totalSeconds,
      isRunning: false,
      isCompleted: false,
    );
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    state = state.copyWith(
      secondsRemaining: 0,
      isRunning: false,
      isCompleted: true,
    );

    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final durationMins = state.totalSeconds ~/ 60;
    final skill = state.selectedSkill;
    final firestore = _ref.read(firestoreRepositoryProvider);

    final session = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      skill: skill,
      durationMinutes: durationMins,
      date: DateTime.now(),
    );

    try {
      // 1. Save focus session
      await firestore.saveFocusSession(user.uid, session);

      // 2. Award XP (+10 XP base + 1 XP per minute focused)
      final xpEarned = 10 + durationMins;
      final profile = _ref.read(userProfileProvider).value;
      if (profile != null) {
        final newXp = profile.xpPoints + xpEarned;
        // Calculate level-up: 100 * level required to level up
        int newLevel = profile.level;
        int targetXp = 100 * newLevel;
        int checkXp = newXp;
        while (checkXp >= targetXp) {
          checkXp -= targetXp;
          newLevel++;
          targetXp = 100 * newLevel;
        }

        await firestore.updateUserProfile(user.uid, {
          'xpPoints': newXp,
          'level': newLevel,
        });
      }

      // 3. Update matching skill growth goal (e.g. Reading, Coding)
      final goals = _ref.read(dynamicGoalsProvider);
      for (var goal in goals) {
        if (goal.category == 'skill_growth') {
          // If goal title matches our skill, increment progress by focused minutes
          final isMatch = goal.title.toLowerCase().contains(skill.toLowerCase());
          if (isMatch) {
            // For reading pages: let's assume 1 page per minute focused
            // For coding: let's assume lesson minutes
            await _ref.read(goalsNotifierProvider.notifier).incrementGoalProgress(goal.id, durationMins);
          }
        }
      }

      // 4. Auto-unlock achievements if applicable
      // Focus Fanatic: Unlocks on completed first focus session
      await firestore.unlockAchievement(user.uid, 'focus_fanatic');

    } catch (e) {
      // Error completing focus session
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
