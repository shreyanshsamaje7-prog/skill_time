import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usage_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../repositories/auth_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToUsage;
  const HomeScreen({super.key, this.onNavigateToUsage});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnimation;
  late AnimationController _glowPulseController;
  late Animation<double> _glowPulseAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Score sweep animation (0 -> target)
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOutCubic),
    );

    // Scale-in animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Neon glow pulse
    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowPulseAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );

    // Start animations with a small delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scaleController.forward();
        _scoreAnimController.forward();
        _syncUsage();
      }
    });
  }

  Future<void> _syncUsage() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref.read(usageTrackingServiceProvider).syncUsageStats(user.uid);
    }
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    _glowPulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildProductivityScoreCard(),
            const SizedBox(height: 16),
            _buildBiggestTimeDrain(),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

 Widget _buildHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SkillTime',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Screen Time → Real Skills',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.purple.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),

      Row(
  children: [

    // Book icon
    Container(
      width: 52,
      height: 52,

      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: AppColors.purple
                .withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),

      child: const Center(
        child: Text(
          '📚',
          style: TextStyle(fontSize: 28),
        ),
      ),
    ),

    const SizedBox(width: 12),

    // Logout button
    GestureDetector(

      onTap: () async {

        final authRepository =
            AuthRepository();

        await authRepository
            .signOut();
      },

      child: Container(
        width: 52,
        height: 52,

        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE91E63),
              Color(0xFF9C27B0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          borderRadius:
              BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63)
                  .withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),

        child: const Icon(
          Icons.logout_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    ),
  ],
)
      
    ],
  );
}

  Widget _buildProductivityScoreCard() {
    final productivityScore = ref.watch(productivityScoreProvider);
    final socialTime = ref.watch(socialTimeProvider);
    
    // Update score animation target
    _scoreAnimation = Tween<double>(begin: 0.0, end: productivityScore).animate(
      CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOutCubic),
    );
    _scoreAnimController.forward(from: 0);

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _scoreAnimation, _glowPulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value.clamp(0.0, 1.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TODAY'S PRODUCTIVITY SCORE",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sectionLabel,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Animated donut chart
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CustomPaint(
                        painter: _ProductivityDonutPainter(
                          progress: _scoreAnimation.value,
                          glowOpacity: _glowPulseAnimation.value,
                          color: AppColors.purple,
                          bgColor: AppColors.surfaceLight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(_scoreAnimation.value * 100).round()}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '/100',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRODUCTIVITY SCORE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.yellowBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '⚠️',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'High Social Usage',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.yellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: 'Based on ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: '${socialTime ~/ 60}h ${socialTime % 60}m',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const TextSpan(text: ' social media today'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBiggestTimeDrain() {
    final usageAsync = ref.watch(dailyUsageProvider);
    
    return usageAsync.when(
      data: (usage) {
        if (usage.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final drain = [...usage]..sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
        final topApp = drain.first;
        final h = topApp.durationMinutes ~/ 60;
        final m = topApp.durationMinutes % 60;
        final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BIGGEST TIME DRAIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${topApp.appName} · $timeStr',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'today',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '= ${(topApp.durationMinutes * 1.5).round()} book pages you didn\'t read',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_getEmoji(topApp.appName), style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      if (widget.onNavigateToUsage != null) {
                        widget.onNavigateToUsage!();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E8C), Color(0xFFFF6EB4)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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

  Widget _buildStatsGrid() {
    final socialTime = ref.watch(socialTimeProvider);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '⏰',
                '${socialTime ~/ 60}h ${socialTime % 60}m',
                'Social Time today',
                AppColors.redLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '📖',
                '383',
                "Pages Lost\ncould've read",
                AppColors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '💻',
                '17',
                'Code Lessons missed',
                AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '🧠',
                '510',
                'Words Lost vocab potential',
                AppColors.pink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String emoji,
    String value,
    String label,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom donut painter for animated productivity score with neon glow
class _ProductivityDonutPainter extends CustomPainter {
  final double progress;
  final double glowOpacity;
  final Color color;
  final Color bgColor;

  _ProductivityDonutPainter({
    required this.progress,
    required this.glowOpacity,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 8.0;

    // Background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Neon glow behind progress
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: glowOpacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        glowPaint,
      );

      // Progress arc
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProductivityDonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowOpacity != glowOpacity;
  }
}
