import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/analytics_provider.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});
  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> with TickerProviderStateMixin {
  late AnimationController _weekCtrl, _monthCtrl, _glowCtrl;
  late Animation<double> _weekScale, _weekSweep, _monthScale, _monthSweep, _glow;

  @override
  void initState() {
    super.initState();
    _weekCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _weekScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _weekCtrl, curve: const Interval(0, 0.4, curve: Curves.elasticOut)));
    _weekSweep = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _weekCtrl, curve: const Interval(0.3, 1, curve: Curves.easeOutCubic)));

    _monthCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _monthScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _monthCtrl, curve: const Interval(0, 0.4, curve: Curves.elasticOut)));
    _monthSweep = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _monthCtrl, curve: const Interval(0.3, 1, curve: Curves.easeOutCubic)));

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glow = Tween(begin: 0.15, end: 0.5).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 200), () { 
      if (mounted) _weekCtrl.forward(); 
    });
    Future.delayed(const Duration(milliseconds: 600), () { 
      if (mounted) _monthCtrl.forward(); 
    });
  }

  @override
  void dispose() { 
    _weekCtrl.dispose(); 
    _monthCtrl.dispose(); 
    _glowCtrl.dispose(); 
    super.dispose(); 
  }

  String _formatHours(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final weeklyAsync = ref.watch(weeklyAnalyticsProvider);
    final monthlyAsync = ref.watch(monthlyAnalyticsProvider);
    final insightsAsync = ref.watch(aiInsightsProvider);
    final trendAsync = ref.watch(sevenDayTrendProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Weekly & monthly summary', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              
              Text('THIS WEEK VS LAST WEEK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              
              weeklyAsync.when(
                data: (weekData) {
                  final stats = weekData['statsThisWeek'] as ReportStats?;
                  final distractingVal = stats?.distractingMinutes ?? 0;
                  final productiveVal = stats?.productiveMinutes ?? 0;
                  final otherVal = stats?.otherMinutes ?? 0;

                  final double distPercent = weekData['distractingPercent'] / 100.0;
                  final double prodPercent = weekData['productivePercent'] / 100.0;
                  final double othPercent = weekData['otherPercent'] / 100.0;

                  return _buildChartCard(
                    _weekScale, 
                    _weekSweep, 
                    [
                      _Seg(distPercent, const Color(0xFFE91E8C)), 
                      _Seg(prodPercent, const Color(0xFF2ECC71)), 
                      _Seg(othPercent, const Color(0xFF3498DB))
                    ], 
                    weekData['centerText'], 
                    [
                      _Leg(const Color(0xFFE91E8C), 'Social', _formatHours(distractingVal)), 
                      _Leg(const Color(0xFF2ECC71), 'Productive', _formatHours(productiveVal)), 
                      _Leg(const Color(0xFF3498DB), 'Other', _formatHours(otherVal))
                    ], 
                    null
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
              ),
              
              const SizedBox(height: 20),
              Text('THIS MONTH VS LAST MONTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              
              monthlyAsync.when(
                data: (monthData) {
                  final double distPercent = (int.tryParse(monthData['centerText'].replaceAll('%', '')) ?? 0) / 100.0;
                  // For month layout, productive and other segments can be estimated or distributed
                  final double prodPercent = distPercent > 0.0 ? (1.0 - distPercent) * 0.55 : 0.5;
                  final double othPercent = 1.0 - distPercent - prodPercent;

                  return _buildChartCard(
                    _monthScale, 
                    _monthSweep, 
                    [
                      _Seg(distPercent, const Color(0xFFFF8C42)), 
                      _Seg(prodPercent, const Color(0xFF2ECC71)), 
                      _Seg(othPercent, const Color(0xFF3498DB))
                    ], 
                    monthData['centerText'], 
                    [
                      _Leg(const Color(0xFFFF8C42), 'Social', monthData['socialHoursStr']), 
                      _Leg(const Color(0xFF2ECC71), 'Productive', monthData['productiveHoursStr']), 
                      _Leg(const Color(0xFF3498DB), 'Other', monthData['otherHoursStr'])
                    ], 
                    _buildMonthStats(monthData)
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
              ),

              const SizedBox(height: 20),
              Text('AI INSIGHTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12), 
              
              insightsAsync.when(
                data: (insights) => _buildAICard(insights),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading insights: $err'),
              ),
              
              const SizedBox(height: 20),
              Text('7-DAY TREND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12), 
              
              trendAsync.when(
                data: (trend) => _buildTrendCard(trend),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading trend: $err'),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(Animation<double> scale, Animation<double> sweep, List<_Seg> segs, String center, List<_Leg> legs, Widget? extra) {
    return AnimatedBuilder(animation: Listenable.merge([scale, sweep, _glow]), builder: (c, _) {
      return Container(width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
        child: Column(children: [
          Row(children: [
            Transform.scale(scale: scale.value.clamp(0.0, 1.0), child: SizedBox(width: 110, height: 110,
              child: CustomPaint(painter: _DonutPainter(segs: segs, center: center, sweep: sweep.value, glow: _glow.value)))),
            const SizedBox(width: 24),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: legs.map((l) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _legRow(l))).toList())),
          ]),
          if (extra != null) ...[const SizedBox(height: 16), extra],
        ]),
      );
    });
  }

  Widget _legRow(_Leg l) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: l.color)),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      Text(l.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]),
  ]);

  Widget _buildMonthStats(Map<String, dynamic> data) => Row(children: [
    Expanded(child: _chip(data['totalScreenTimeChange'], 'vs last month', AppColors.green)),
    Expanded(child: _chip(data['productiveTimeChange'], 'more productive', AppColors.green)),
    Expanded(child: _chip(data['scoreImprovement'], 'score improved', AppColors.green)),
  ]);

  Widget _chip(String v, String l, Color c) => Column(children: [
    Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
    const SizedBox(height: 2),
    Text(l, style: TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
  ]);

  Widget _buildAICard(List<AIInsightItem> insights) {
    if (insights.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
        child: Center(child: Text('AI is gathering screen logs. Check back soon.', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
      child: Column(
        children: insights.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _insightRow(item.emoji, item.title, item.description),
              if (i < insights.length - 1)
                const Divider(color: AppColors.surfaceLight, height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _insightRow(String e, String t, String s) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(e, style: const TextStyle(fontSize: 18)))),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text(s, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
    ])),
  ]);

  Widget _buildTrendCard(List<DailyTrendItem> trend) {
    if (trend.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
        child: Center(child: Text('No trend logs yet.', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: trend.map((item) {
          // Curate beautiful alternating gradients based on screentime severity
          final Color color = item.totalMinutes > 120 
              ? const Color(0xFFE91E8C) 
              : item.totalMinutes > 60 
                  ? const Color(0xFFB07FEB) 
                  : const Color(0xFF3498DB);

          return _bar(item.dayName, color, item.heightFraction);
        }).toList(),
      ),
    );
  }

  Widget _bar(String d, Color c, double i) => Column(children: [
    Container(
      width: 34, 
      height: 50, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8), 
        color: c.withValues(alpha: 0.3 + i * 0.7)
      ),
    ),
    const SizedBox(height: 8),
    Text(d, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
  ]);
}

class _Seg { final double value; final Color color; _Seg(this.value, this.color); }
class _Leg { final Color color; final String label, value; _Leg(this.color, this.label, this.value); }

class _DonutPainter extends CustomPainter {
  final List<_Seg> segs; final String center; final double sweep, glow;
  _DonutPainter({required this.segs, required this.center, required this.sweep, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    const sw = 14.0; const gap = 0.04;
    double sa = -math.pi / 2; double drawn = 0; final total = sweep * 2 * math.pi;
    for (final s in segs) {
      final full = s.value * 2 * math.pi; final rem = total - drawn;
      if (rem <= 0) break;
      final actual = math.min(full - gap, rem); if (actual <= 0) break;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), sa, actual, false,
        Paint()..color = s.color.withValues(alpha: glow * 0.35)..style = PaintingStyle.stroke..strokeWidth = sw + 12..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), sa, actual, false,
        Paint()..color = s.color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
      sa += full; drawn += full;
    }
    final op = (sweep * 2).clamp(0.0, 1.0);
    final tp = TextPainter(text: TextSpan(text: center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary.withValues(alpha: op))), textDirection: TextDirection.ltr);
    tp.layout(); tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) => o.sweep != sweep || o.glow != glow;
}
