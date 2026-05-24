import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/achievements_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/focus_provider.dart';
import '../models/achievement.dart';

class AchieveScreen extends ConsumerStatefulWidget {
  const AchieveScreen({super.key});
  @override
  ConsumerState<AchieveScreen> createState() => _AchieveScreenState();
}

class _AchieveScreenState extends ConsumerState<AchieveScreen> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _badgeEntranceCtrl;
  late Animation<double> _badgeScaleAnim;
  late Animation<double> _badgeBloomAnim;
  int _selectedBadge = 0;

  @override
  void initState() {
    super.initState();
    // Continuous neon glow pulse for badges
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.2, end: 0.7).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Badge entrance animation (scale-in + bloom)
    _badgeEntranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _badgeScaleAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _badgeEntranceCtrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _badgeBloomAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _badgeEntranceCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) { 
        _badgeEntranceCtrl.forward(); 
      }
    });
  }

  @override
  void dispose() { 
    _pulseCtrl.dispose(); 
    _badgeEntranceCtrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Achievements', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Level up your real life 🎮', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              
              profileAsync.when(
                data: (profile) => profile != null ? _buildCurrentRankCard(profile) : const SizedBox.shrink(),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
                error: (err, _) => Text('Error: $err'),
              ),
              
              const SizedBox(height: 20),
              _buildFocusTimerCard(),
              const SizedBox(height: 20),
              
              Text('ALL RANKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12), 
              _buildAllRanks(profileAsync.value),
              const SizedBox(height: 20),
              Text('HOW TO EARN XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12), 
              _buildEarnXPCard(),
              const SizedBox(height: 20),
              Text('BADGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12), 
              
              achievementsAsync.when(
                data: (badges) => _buildRecentBadges(badges),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
                error: (err, _) => Text('Error: $err'),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentRankCard(dynamic profile) {
    final xpProgress = ref.watch(xpProgressProvider);
    final totalXp = profile.xpPoints;
    final level = profile.level;
    final rankName = level < 5 ? 'Bronze' : level < 10 ? 'Silver' : level < 15 ? 'Gold' : 'Diamond';
    final rankEmoji = level < 5 ? '🥉' : level < 10 ? '🥈' : level < 15 ? '🥇' : '💎';
    final xpToNext = 100 * level;
    
    // XP within current level
    int startXpOfCurrentLevel = 0;
    for (int i = 1; i < level; i++) {
      startXpOfCurrentLevel += 100 * i;
    }
    final currentXpInLevel = totalXp - startXpOfCurrentLevel;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade500]),
                      boxShadow: [
                        BoxShadow(color: AppColors.purple.withValues(alpha: _pulseAnim.value * 0.4), blurRadius: 20, spreadRadius: 3),
                      ],
                    ),
                    child: Center(child: Text(rankEmoji, style: const TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT RANK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(rankName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('Level $level Achiever', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('$totalXp', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.orange)),
                      Text('Total XP', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level $level', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Text('Next: ${startXpOfCurrentLevel + xpToNext} XP', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: AppColors.surfaceLight),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: xpProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.blue,
                      boxShadow: [
                        BoxShadow(color: AppColors.blue.withValues(alpha: _pulseAnim.value * 0.5), blurRadius: 10, spreadRadius: 1),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(child: Text('${(xpProgress * 100).round()}% progress to level ${level + 1} ($currentXpInLevel/$xpToNext XP)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocusTimerCard() {
    final timerState = ref.watch(focusTimerProvider);
    final timerNotifier = ref.read(focusTimerProvider.notifier);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('FOCUS SESSION TIMER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
                if (timerState.isCompleted)
                  const Text('🎉 FOCUS ACHIEVED! +10 XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green))
                else if (timerState.isRunning)
                  const Text('⚡ FOCUSING ACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange))
                else
                  Text('READY TO FOCUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Glowing Pomodoro circular countdown
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0 - timerState.progress,
                        strokeWidth: 6,
                        backgroundColor: AppColors.surfaceLight,
                        color: timerState.isRunning ? AppColors.pink : AppColors.purple,
                      ),
                      Text(
                        timerState.timeString,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Skill Target:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      DropdownButton<String>(
                        dropdownColor: AppColors.cardBackground,
                        value: timerState.selectedSkill,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'Coding', child: Text('Coding 💻')),
                          DropdownMenuItem(value: 'Reading', child: Text('Reading 📖')),
                          DropdownMenuItem(value: 'Vocabulary', child: Text('Vocabulary 🧠')),
                        ],
                        onChanged: timerState.isRunning ? null : (val) => timerNotifier.setSelectedSkill(val!),
                      ),
                      const SizedBox(height: 12),
                      // Duration presets
                      Row(
                        children: [
                          _timerDurBtn(1, '1m (Test)'),
                          const SizedBox(width: 6),
                          _timerDurBtn(15, '15m'),
                          const SizedBox(width: 6),
                          _timerDurBtn(25, '25m'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: timerState.isRunning ? AppColors.orange : AppColors.purple,
                    minimumSize: const Size(120, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  label: Text(timerState.isRunning ? 'Pause' : 'Start Focus', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: timerState.isRunning ? timerNotifier.pauseTimer : timerNotifier.startTimer,
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.surfaceLight),
                    minimumSize: const Size(120, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text('Reset'),
                  onPressed: timerNotifier.resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerDurBtn(int mins, String label) {
    final timerState = ref.watch(focusTimerProvider);
    final isSelected = timerState.totalSeconds == mins * 60;
    return GestureDetector(
      onTap: timerState.isRunning ? null : () => ref.read(focusTimerProvider.notifier).setDuration(mins),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple.withValues(alpha: 0.2) : AppColors.surfaceLight,
          border: isSelected ? Border.all(color: AppColors.purple, width: 1.5) : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildAllRanks(dynamic profile) {
    final level = profile?.level ?? 1;
    return AnimatedBuilder(animation: Listenable.merge([_badgeEntranceCtrl, _pulseAnim]), builder: (context, _) {
      return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildRankItem('🥉', 'BRONZE', 'Lvl 1-4', level >= 1 ? (level < 5 ? 'CURRENT' : 'DONE ✓') : 'LOCKED 🔒', level >= 1, level < 5, 0),
          _buildRankItem('🥈', 'SILVER', 'Lvl 5-9', level >= 5 ? (level < 10 ? 'CURRENT' : 'DONE ✓') : 'LOCKED 🔒', level >= 5, level >= 5 && level < 10, 1),
          _buildRankItem('🥇', 'GOLD', 'Lvl 10-14', level >= 10 ? (level < 15 ? 'CURRENT' : 'DONE ✓') : 'LOCKED 🔒', level >= 10, level >= 10 && level < 15, 2),
          _buildRankItem('💎', 'DIAMOND', 'Lvl 15-19', level >= 15 ? (level < 20 ? 'CURRENT' : 'DONE ✓') : 'LOCKED 🔒', level >= 15, level >= 15 && level < 20, 3),
          _buildRankItem('👑', 'MASTER', 'Lvl 20+', level >= 20 ? 'CURRENT' : 'LOCKED 🔒', level >= 20, level >= 20, 4),
        ]));
    });
  }

  Widget _buildRankItem(String emoji, String name, String range, String status, bool unlocked, bool isCurrent, int index) {
    final delay = index * 0.1;
    final scaleVal = Curves.elasticOut.transform(((_badgeScaleAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0));
    final bloomVal = ((_badgeBloomAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);

    return Transform.scale(scale: 0.5 + (scaleVal * 0.5),
      child: Opacity(opacity: scaleVal.clamp(0.0, 1.0),
        child: Column(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: (unlocked || isCurrent) ? AppColors.purple.withValues(alpha: isCurrent ? 0.15 : 0.08) : Colors.transparent,
              border: (unlocked || isCurrent) ? Border.all(color: AppColors.purple.withValues(alpha: isCurrent ? 0.7 : 0.35), width: isCurrent ? 2 : 1.5) : null,
              boxShadow: unlocked ? [
                BoxShadow(color: AppColors.purple.withValues(alpha: _pulseAnim.value * (isCurrent ? 0.35 : 0.2) * bloomVal), blurRadius: 18, spreadRadius: isCurrent ? 3 : 1),
                BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: _pulseAnim.value * (isCurrent ? 0.2 : 0.12) * bloomVal), blurRadius: 30, spreadRadius: isCurrent ? 6 : 3),
                BoxShadow(color: AppColors.purple.withValues(alpha: _pulseAnim.value * (isCurrent ? 0.1 : 0.06) * bloomVal), blurRadius: 45, spreadRadius: isCurrent ? 10 : 5),
              ] : []),
            child: Center(child: Text(emoji, style: TextStyle(fontSize: 24,
              color: unlocked ? null : Colors.white.withValues(alpha: 0.3))))),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5,
            color: isCurrent ? AppColors.orange : unlocked ? AppColors.textSecondary : AppColors.textMuted)),
          Text(range, style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600,
            color: status.contains('CURRENT') ? AppColors.purple : status.contains('DONE') ? AppColors.green : AppColors.textMuted)),
        ])));
  }

  Widget _buildEarnXPCard() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
      child: Column(children: [
        _buildXPRow('📉', 'Reduce Social Usage', 'Save 30 min below your daily average', '+50 XP', AppColors.green),
        const Divider(color: AppColors.surfaceLight, height: 24),
        _buildXPRow('🎯', 'Complete a Goal', 'Finish any daily goal fully', '+100 XP', AppColors.green),
        const Divider(color: AppColors.surfaceLight, height: 24),
        _buildXPRow('🔥', 'Maintain a Streak', 'Keep any goal active 3+ days', '+100 XP', AppColors.green),
        const Divider(color: AppColors.surfaceLight, height: 24),
        _buildXPRow('📚', 'Learning Minutes', 'Focused coding, reading or vocab', '+1 XP/min', AppColors.green),
      ]));
  }

  Widget _buildXPRow(String emoji, String title, String subtitle, String xpText, Color xpColor) {
    return Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(border: Border.all(color: xpColor, width: 1), borderRadius: BorderRadius.circular(8)),
        child: Text(xpText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: xpColor))),
    ]);
  }

  Widget _buildRecentBadges(List<Achievement> achievements) {
    if (achievements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
        child: Center(
          child: Text('Keep going to unlock achievements!', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
      );
    }

    return Column(
      children: achievements.asMap().entries.map((entry) {
        final i = entry.key;
        final b = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: i < achievements.length - 1 ? 10 : 0),
          child: GestureDetector(
            onTap: () => setState(() => _selectedBadge = i),
            child: _buildBadgeTile(b, i == _selectedBadge),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBadgeTile(Achievement b, bool isSelected) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        final Color accentColor = b.isUnlocked ? AppColors.green : AppColors.textMuted;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardBackgroundLight : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.purple.withValues(alpha: 0.6) : AppColors.surfaceLight.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 0.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: AppColors.purple.withValues(alpha: _pulseAnim.value * 0.25), blurRadius: 24, spreadRadius: 2),
                  ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(b.icon, style: const TextStyle(fontSize: 22))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: b.isUnlocked ? AppColors.textPrimary : AppColors.textSecondary)),
                    Text(b.description, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${b.xpReward}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: accentColor)),
                  Text(b.isUnlocked ? 'Earned' : 'Locked', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
