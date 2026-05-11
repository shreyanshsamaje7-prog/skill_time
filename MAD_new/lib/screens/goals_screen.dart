import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {
  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;
  late Animation<double> _btnGlow;
  late AnimationController _progressCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  final List<_GoalData> _goals = [
    _GoalData('🚫', 'Limit Instagram', 'Target: 45 min/day · Today: 1h 28m used', 0.62, AppColors.red, 'Over limit today', AppColors.red, '3 day streak'),
    _GoalData('📖', 'Read 20 pages/day', '16 pages done · 4 remaining', 0.80, AppColors.purple, 'On track', AppColors.green, '12 day streak 🔥'),
    _GoalData('💻', '1 Code Lesson/day', 'Not started yet · 8h left today', 0.0, AppColors.textMuted, 'Not started', AppColors.red, '0 streak'),
    _GoalData('🧠', '10 Vocab Words/day', '4 words done · 6 remaining', 0.40, AppColors.orange, 'In progress', AppColors.orange, '7 day streak'),
  ];

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _btnScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.08).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_btnCtrl);
    _btnGlow = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOutCubic));

    // Animated progress fill
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    // Subtle glow pulse
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _progressCtrl.forward(); });
  }

  @override
  void dispose() { _btnCtrl.dispose(); _progressCtrl.dispose(); _glowCtrl.dispose(); super.dispose(); }

  void _onAddGoalTap() { _btnCtrl.forward(from: 0); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Goals', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Set limits · Build skills', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        Text('ACTIVE GOALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._goals.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(bottom: e.key < _goals.length - 1 ? 12 : 0),
          child: _buildAnimatedGoalCard(e.value, e.key),
        )),
        const SizedBox(height: 20),
        _buildAddGoalButton(),
        const SizedBox(height: 20),
        Text('WEEKLY GOAL SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildWeeklySummary(),
        const SizedBox(height: 30),
      ]),
    ));
  }

  Widget _buildAnimatedGoalCard(_GoalData g, int index) {
    return AnimatedBuilder(animation: Listenable.merge([_progressCtrl, _glowAnim]), builder: (context, _) {
      final delay = index * 0.12;
      final p = Curves.easeOutCubic.transform(((_progressCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0));
      final animProgress = g.progress * p;
      final animPercent = (g.progress * 100 * p).round();

      return Container(width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(g.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(g.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            Text('$animPercent%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: g.progressColor)),
          ]),
          const SizedBox(height: 6),
          Text(g.subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          // Animated progress bar with glow
          Container(height: 8, width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: AppColors.surfaceLight),
            child: FractionallySizedBox(alignment: Alignment.centerLeft,
              widthFactor: animProgress.clamp(0.0, 1.0),
              child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: g.progressColor,
                boxShadow: animProgress > 0 ? [
                  BoxShadow(color: g.progressColor.withValues(alpha: _glowAnim.value * 0.4), blurRadius: 8, spreadRadius: 1),
                ] : [])))),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: g.statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(g.statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: g.statusColor))),
            Text(g.streak, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ]));
    });
  }

  Widget _buildAddGoalButton() {
    return AnimatedBuilder(animation: _btnCtrl, builder: (context, _) {
      return GestureDetector(onTap: _onAddGoalTap,
        child: Transform.scale(scale: _btnScale.value,
          child: Container(width: double.infinity, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E8C), Color(0xFFFF6EB4)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: const Color(0xFFE91E8C).withValues(alpha: _btnGlow.value * 0.5), blurRadius: 20 + (_btnGlow.value * 15), spreadRadius: _btnGlow.value * 5),
                BoxShadow(color: const Color(0xFFFF6EB4).withValues(alpha: _btnGlow.value * 0.3), blurRadius: 30 + (_btnGlow.value * 20), spreadRadius: _btnGlow.value * 8),
              ]),
            child: const Center(child: Text('+ Add New Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))))));
    });
  }

  Widget _buildWeeklySummary() {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
      child: Row(children: [
        Expanded(child: _buildSummaryItem('2/4', 'Goals Met', AppColors.green)),
        Container(width: 1, height: 40, color: AppColors.surfaceLight),
        Expanded(child: _buildSummaryItem('12', 'Best Streak', AppColors.orange)),
        Container(width: 1, height: 40, color: AppColors.surfaceLight),
        Expanded(child: _buildSummaryItem('55', 'Score', AppColors.purple)),
      ]));
  }

  Widget _buildSummaryItem(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}

class _GoalData {
  final String emoji, title, subtitle, statusText, streak;
  final double progress;
  final Color progressColor, statusColor;
  _GoalData(this.emoji, this.title, this.subtitle, this.progress, this.progressColor, this.statusText, this.statusColor, this.streak);
}
