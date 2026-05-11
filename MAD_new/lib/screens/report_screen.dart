import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with TickerProviderStateMixin {
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

    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _weekCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 600), () { if (mounted) _monthCtrl.forward(); });
  }

  @override
  void dispose() { _weekCtrl.dispose(); _monthCtrl.dispose(); _glowCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Report', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Weekly & monthly summary', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        Text('THIS WEEK VS LAST WEEK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildChartCard(_weekScale, _weekSweep, [_Seg(0.75, const Color(0xFFE91E8C)), _Seg(0.13, const Color(0xFF2ECC71)), _Seg(0.12, const Color(0xFF3498DB))], '75%', [_Leg(const Color(0xFFE91E8C), 'Social', '29h 43m'), _Leg(const Color(0xFF2ECC71), 'Productive', '5h 21m'), _Leg(const Color(0xFF3498DB), 'Other', '3h 40m')], null),
        const SizedBox(height: 20),
        Text('THIS MONTH VS LAST MONTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildChartCard(_monthScale, _monthSweep, [_Seg(0.70, const Color(0xFFFF8C42)), _Seg(0.15, const Color(0xFF2ECC71)), _Seg(0.15, const Color(0xFF3498DB))], '70%', [_Leg(const Color(0xFFFF8C42), 'Social', '118h 32m'), _Leg(const Color(0xFF2ECC71), 'Productive', '24h 15m'), _Leg(const Color(0xFF3498DB), 'Other', '16h 10m')], _buildMonthStats()),
        const SizedBox(height: 20),
        Text('AI INSIGHTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
        const SizedBox(height: 12), _buildAICard(),
        const SizedBox(height: 20),
        Text('7-DAY TREND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
        const SizedBox(height: 12), _buildTrendCard(),
        const SizedBox(height: 30),
      ]),
    ));
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

  Widget _buildMonthStats() => Row(children: [
    Expanded(child: _chip('−8h 20m', 'vs last month', AppColors.green)),
    Expanded(child: _chip('+4h 30m', 'more productive', AppColors.green)),
    Expanded(child: _chip('↑ 12%', 'score improved', AppColors.green)),
  ]);

  Widget _chip(String v, String l, Color c) => Column(children: [
    Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
    const SizedBox(height: 2),
    Text(l, style: TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
  ]);

  Widget _buildAICard() => Container(width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
    child: Column(children: [
      _insightRow('🔴', 'Peak usage: 8–10pm', 'You scroll most before sleep. This disrupts your sleep cycle significantly.'),
      const Divider(color: AppColors.surfaceLight, height: 24),
      _insightRow('⚡', 'Monday is worst day', '7h 20m avg — 2x higher than Friday. Weekend mindset carries over.'),
      const Divider(color: AppColors.surfaceLight, height: 24),
      _insightRow('✅', 'Tuesday improving', "Down 45m vs last Tuesday. Keep it up — you're building the habit!"),
    ]));

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

  Widget _buildTrendCard() => Container(width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _bar('Mon', const Color(0xFFE91E8C), 0.7), _bar('Tue', const Color(0xFFB07FEB), 0.5),
      _bar('Wed', const Color(0xFFE91E8C), 0.6), _bar('Thu', const Color(0xFFFF6EB4), 0.8),
      _bar('Fri', const Color(0xFF5A5E72), 0.3), _bar('Sat', const Color(0xFF5A5E72), 0.35),
      _bar('Sun', const Color(0xFF3498DB), 0.65),
    ]));

  Widget _bar(String d, Color c, double i) => Column(children: [
    Container(width: 34, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: c.withValues(alpha: 0.3 + i * 0.7))),
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
