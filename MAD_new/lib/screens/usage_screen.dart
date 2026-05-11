import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/usage_provider.dart';
import '../models/app_usage.dart';

class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});
  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> with TickerProviderStateMixin {
  late AnimationController _barController;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _barController.forward(); });
  }

  @override
  void dispose() { _barController.dispose(); _glowCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(dailyUsageProvider);

    return SafeArea(
      child: usageAsync.when(
        data: (usage) => _buildContent(usage),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildContent(List<AppUsage> usage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usage', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text("Today's screen time breakdown", style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          _buildTotalScreenTimeCard(usage),
          const SizedBox(height: 20),
          Text('HOURLY PATTERN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildHourlyPatternCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTotalScreenTimeCard(List<AppUsage> usage) {
    // Sort usage by duration descending
    final sortedUsage = [...usage]..sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
    final totalMinutes = usage.fold(0, (sum, item) => sum + item.durationMinutes);
    final maxMinutes = sortedUsage.isNotEmpty ? sortedUsage.first.durationMinutes : 1;

    return AnimatedBuilder(
      animation: Listenable.merge([_barController, _glowAnim]),
      builder: (context, _) {
        final p = _barController.value;
        final animTotalMin = (totalMinutes * p).round();
        final h = animTotalMin ~/ 60;
        final m = animTotalMin % 60;
        final timeStr = h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL SCREEN TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeStr, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  if (totalMinutes == 0)
                    Text('No data yet', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('active usage', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.purple)),
                      ],
                    ),
                ],
              ),
              if (usage.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...sortedUsage.asMap().entries.map((e) {
                  final i = e.key;
                  final app = e.value;
                  final delay = (i * 0.1).clamp(0.0, 0.5);
                  final barP = Curves.easeOutCubic.transform(((p - delay) / (1.0 - delay)).clamp(0.0, 1.0));
                  final animMin = (app.durationMinutes * barP).round();
                  String animTime = animMin >= 60 ? '${animMin ~/ 60}h ${(animMin % 60).toString().padLeft(2, '0')}m' : '${animMin}m';
                  
                  final List<Color> colors = app.category == AppCategory.productive 
                      ? [const Color(0xFF00C9A7), const Color(0xFF2ECC71)]
                      : app.category == AppCategory.distracting
                          ? [const Color(0xFFE91E8C), const Color(0xFFFF6EB4)]
                          : [const Color(0xFF3498DB), const Color(0xFF5DADE2)];

                  return Padding(
                    padding: EdgeInsets.only(bottom: i < sortedUsage.length - 1 ? 14 : 0),
                    child: _buildAnimatedRow(
                      _getEmoji(app.appName), 
                      app.appName, 
                      colors, 
                      animTime, 
                      (app.durationMinutes / maxMinutes) * barP, 
                      colors[0],
                    ),
                  );
                }),
              ] else if (p > 0.8) ...[
                const SizedBox(height: 40),
                Center(child: Text('No app usage recorded for today.', style: TextStyle(color: AppColors.textMuted))),
                const SizedBox(height: 20),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getEmoji(String appName) {
    final name = appName.toLowerCase();
    if (name.contains('insta')) return '📷';
    if (name.contains('youtube')) return '▶️';
    if (name.contains('tiktok')) return '🎵';
    if (name.contains('whatsapp')) return '💬';
    if (name.contains('twitter') || name.contains(' x ')) return '✖️';
    if (name.contains('facebook')) return '👥';
    if (name.contains('kindle') || name.contains('book')) return '📖';
    if (name.contains('duolingo')) return '🦉';
    if (name.contains('notion')) return '📝';
    return '📱';
  }

  Widget _buildAnimatedRow(String emoji, String name, List<Color> colors, String time, double barW, Color glowColor) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      SizedBox(width: 72, child: Text(name, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
      Expanded(child: Container(height: 10,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: AppColors.surfaceLight.withValues(alpha: 0.3)),
        child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: barW.clamp(0.0, 1.0),
          child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(colors: colors),
            boxShadow: [BoxShadow(color: glowColor.withValues(alpha: _glowAnim.value * 0.3), blurRadius: 8, spreadRadius: 1)]))))),
      const SizedBox(width: 12),
      SizedBox(width: 54, child: Text(time, textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
    ]);
  }

  Widget _buildHourlyPatternCard() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
      child: Column(children: [
        SizedBox(height: 120, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
          _buildBar(0.25, '8am', const Color(0xFF5A5E72), false),
          _buildBar(0.35, '10am', const Color(0xFF5A5E72), false),
          _buildBar(0.70, '12pm', const Color(0xFFE91E8C), true),
          _buildBar(0.30, '2pm', const Color(0xFF5A5E72), false),
          _buildBar(0.55, '4pm', const Color(0xFFE91E8C), true),
          _buildBar(0.30, '6pm', const Color(0xFF5A5E72), false),
          _buildBar(0.85, '8pm', const Color(0xFFFF8C42), true),
          _buildBar(0.30, '10pm', const Color(0xFF5A5E72), false),
        ])),
      ]));
  }

  Widget _buildBar(double height, String label, Color color, bool hl) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Container(width: 28, height: 100 * height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6),
          gradient: hl ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.7), color]) : null,
          color: hl ? null : color.withValues(alpha: 0.4))),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(fontSize: 10, color: hl ? color : AppColors.textMuted, fontWeight: hl ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }
}

class _AppData {
  final String emoji, name, timeLabel;
  final int minutes;
  final List<Color> colors;
  final double barFraction;
  _AppData(this.emoji, this.name, this.minutes, this.colors, this.timeLabel, this.barFraction);
}
