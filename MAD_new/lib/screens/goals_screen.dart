import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/goal.dart';
import '../providers/goals_provider.dart';
import '../providers/usage_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> with TickerProviderStateMixin {
  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;
  late Animation<double> _btnGlow;
  late AnimationController _progressCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

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

    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 300), () { 
      if (mounted) _progressCtrl.forward(); 
    });
  }

  @override
  void dispose() { 
    _btnCtrl.dispose(); 
    _progressCtrl.dispose(); 
    _glowCtrl.dispose(); 
    super.dispose(); 
  }

  void _onAddGoalTap() {
    _btnCtrl.forward(from: 0).then((_) {
      _showAddGoalDialog();
    });
  }

  void _showAddGoalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddGoalDialog(),
    );
  }

  void _showGoalActionDialog(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5)),
        title: Row(
          children: [
            Text(goal.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(child: Text(goal.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(
          goal.category == 'screen_limit'
              ? 'This is a screen limit goal. It is automatically updated in real-time as you use your device.'
              : 'Log manual progress or delete this goal. Learning minutes also sync directly when you complete Focus sessions!',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteGoal(goal);
            },
            child: const Text('Delete Goal', style: TextStyle(color: AppColors.redLight)),
          ),
          if (goal.category == 'skill_growth')
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
              onPressed: () {
                Navigator.pop(context);
                _showLogProgressDialog(goal);
              },
              child: const Text('Log 15 min', style: TextStyle(color: Colors.white)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogProgressDialog(Goal goal) {
    int minutes = 15;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log Skill Progress', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How many minutes did you spend on "${goal.title}"?',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                    onPressed: () {
                      if (minutes > 5) setState(() => minutes -= 5);
                    },
                  ),
                  Text('$minutes min', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    onPressed: () => setState(() => minutes += 5),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
              onPressed: () {
                ref.read(goalsNotifierProvider.notifier).incrementGoalProgress(goal.id, minutes);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged $minutes minutes to "${goal.title}"!')),
                );
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Goal?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete the goal "${goal.title}"?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              ref.read(goalsNotifierProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal deleted successfully.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(dynamicGoalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Goals', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Set limits · Build skills', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Text('ACTIVE GOALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              
              if (goals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text('No active goals set.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Set app limits or skill-growth targets below.', style: TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              else
                ...goals.asMap().entries.map((e) => Padding(
                  padding: EdgeInsets.only(bottom: e.key < goals.length - 1 ? 12 : 0),
                  child: _buildAnimatedGoalCard(e.value, e.key),
                )),
                
              const SizedBox(height: 20),
              _buildAddGoalButton(),
              const SizedBox(height: 20),
              Text('WEEKLY GOAL SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _buildWeeklySummary(goals),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedGoalCard(Goal g, int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressCtrl, _glowAnim]),
      builder: (context, _) {
        final delay = (index * 0.12).clamp(0.0, 0.5);
        final p = Curves.easeOutCubic.transform(((_progressCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0));
        
        final animProgress = g.progress * p;
        final animPercent = (g.progress * 100 * p).round();

        // Determine colors based on category/limit status
        final isLimit = g.category == 'screen_limit';
        final isOverLimit = isLimit && g.currentMinutes > g.targetMinutes;
        
        final Color themeColor = isOverLimit 
            ? AppColors.red 
            : isLimit 
                ? AppColors.teal 
                : g.title.toLowerCase().contains('read') 
                    ? AppColors.purple 
                    : g.title.toLowerCase().contains('code') 
                        ? AppColors.orange 
                        : AppColors.blue;

        final subtitle = isLimit 
            ? 'Limit: ${g.targetMinutes} min/day · Today: ${g.currentMinutes}m used'
            : '${g.currentMinutes} minutes done · ${g.currentMinutes >= g.targetMinutes ? 0 : g.targetMinutes - g.currentMinutes}m remaining';

        final statusColor = isOverLimit 
            ? AppColors.red 
            : isLimit 
                ? AppColors.green 
                : g.currentMinutes >= g.targetMinutes 
                    ? AppColors.green 
                    : AppColors.orange;

        return GestureDetector(
          onTap: () => _showGoalActionDialog(g),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                    Text(g.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(g.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                    Text('$animPercent%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: themeColor)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                
                // Animated progress bar with glow
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: AppColors.surfaceLight),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animProgress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: themeColor,
                        boxShadow: animProgress > 0
                            ? [
                                BoxShadow(color: themeColor.withValues(alpha: _glowAnim.value * 0.4), blurRadius: 8, spreadRadius: 1),
                              ]
                            : [],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(g.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                    Text(g.streak > 0 ? '${g.streak} day streak 🔥' : '0 streak', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddGoalButton() {
    return AnimatedBuilder(animation: _btnCtrl, builder: (context, _) {
      return GestureDetector(
        onTap: _onAddGoalTap,
        child: Transform.scale(
          scale: _btnScale.value,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E8C), Color(0xFFFF6EB4)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: const Color(0xFFE91E8C).withValues(alpha: _btnGlow.value * 0.5), blurRadius: 20 + (_btnGlow.value * 15), spreadRadius: _btnGlow.value * 5),
                BoxShadow(color: const Color(0xFFFF6EB4).withValues(alpha: _btnGlow.value * 0.3), blurRadius: 30 + (_btnGlow.value * 20), spreadRadius: _btnGlow.value * 8),
              ],
            ),
            child: const Center(
              child: Text('+ Add New Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildWeeklySummary(List<Goal> goals) {
    int metCount = 0;
    int bestStreak = 0;
    for (var g in goals) {
      if (g.category == 'screen_limit') {
        if (g.currentMinutes <= g.targetMinutes) metCount++;
      } else {
        if (g.currentMinutes >= g.targetMinutes) metCount++;
      }
      if (g.streak > bestStreak) bestStreak = g.streak;
    }

    final productivityScore = ref.watch(productivityScoreProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSummaryItem('$metCount/${goals.length}', 'Goals Met', AppColors.green)),
          Container(width: 1, height: 40, color: AppColors.surfaceLight),
          Expanded(child: _buildSummaryItem('$bestStreak', 'Best Streak', AppColors.orange)),
          Container(width: 1, height: 40, color: AppColors.surfaceLight),
          Expanded(child: _buildSummaryItem('${(productivityScore * 100).round()}', 'Focus Score', AppColors.purple)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _AddGoalDialog extends ConsumerStatefulWidget {
  const _AddGoalDialog();
  @override
  ConsumerState<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  String _selectedEmoji = '🚫';
  String _selectedCategory = 'screen_limit';
  int _targetMinutes = 45;

  // Preset templates to make adding goals quick & aesthetic
  final List<Map<String, dynamic>> _presets = [
    {'title': 'Limit Instagram', 'emoji': '🚫', 'category': 'screen_limit', 'target': 45},
    {'title': 'Limit YouTube', 'emoji': '🚫', 'category': 'screen_limit', 'target': 60},
    {'title': 'Read Books', 'emoji': '📖', 'category': 'skill_growth', 'target': 20},
    {'title': 'Code Lessons', 'emoji': '💻', 'category': 'skill_growth', 'target': 30},
    {'title': 'Vocabulary Practice', 'emoji': '🧠', 'category': 'skill_growth', 'target': 15},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _titleController.text = preset['title'];
      _selectedEmoji = preset['emoji'];
      _selectedCategory = preset['category'];
      _targetMinutes = preset['target'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 24, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create New Goal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Preset Chips
              Text('PRESETS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.sectionLabel, letterSpacing: 1)),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: AppColors.surfaceLight,
                        side: BorderSide.none,
                        label: Text('${preset['emoji']} ${preset['title']}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: () => _applyPreset(preset),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Title input
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.surfaceLight), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.purple), borderRadius: BorderRadius.circular(12)),
                  errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.red), borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a goal title' : null,
              ),
              const SizedBox(height: 16),

              // Emoji Selection
              Row(
                children: [
                  Text('Emoji:  ', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  DropdownButton<String>(
                    dropdownColor: AppColors.cardBackground,
                    value: _selectedEmoji,
                    style: const TextStyle(fontSize: 20),
                    underline: const SizedBox.shrink(),
                    items: ['🚫', '📖', '💻', '🧠', '⚡', '🎨', '🎵', '🏋️']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedEmoji = val!),
                  ),
                  const Spacer(),
                  Text('Type:  ', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  DropdownButton<String>(
                    dropdownColor: AppColors.cardBackground,
                    value: _selectedCategory,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'screen_limit', child: Text('Screen Limit', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'skill_growth', child: Text('Skill Growth', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Target minutes slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedCategory == 'screen_limit' ? 'Daily App Limit' : 'Daily Study Target',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('$_targetMinutes min/day', style: const TextStyle(color: AppColors.purpleLight, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _targetMinutes.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                activeColor: AppColors.purple,
                inactiveColor: AppColors.surfaceLight,
                onChanged: (val) => setState(() => _targetMinutes = val.round()),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ref.read(goalsNotifierProvider.notifier).addGoal(
                      _titleController.text.trim(),
                      _selectedEmoji,
                      _selectedCategory,
                      _targetMinutes,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Created goal "${_titleController.text}" successfully!')),
                    );
                  }
                },
                child: const Text('Create Goal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
