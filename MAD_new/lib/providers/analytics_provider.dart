import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'auth_provider.dart';
import '../models/app_usage.dart';
import 'goals_provider.dart';
import '../repositories/firestore_repository.dart';

final usageHistoryProvider = StreamProvider<List<AppUsage>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  
  final firestore = ref.watch(firestoreRepositoryProvider);
  final start = DateTime.now().subtract(const Duration(days: 60)); // Fetch 60 days for monthly comparison
  final end = DateTime.now();
  
  return firestore.getUsageInRange(user.uid, start, end).map((list) {
    return list;
  });
});

// Aggregates statistics for a list of app usage
class ReportStats {
  final int totalMinutes;
  final int productiveMinutes;
  final int distractingMinutes;
  final int otherMinutes;

  ReportStats({
    required this.totalMinutes,
    required this.productiveMinutes,
    required this.distractingMinutes,
    required this.otherMinutes,
  });

  double get distractingRatio => totalMinutes == 0 ? 0.0 : distractingMinutes / totalMinutes;
  double get productiveRatio => totalMinutes == 0 ? 0.0 : productiveMinutes / totalMinutes;
  double get otherRatio => totalMinutes == 0 ? 0.0 : otherMinutes / totalMinutes;
}

final weeklyAnalyticsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final historyAsync = ref.watch(usageHistoryProvider);

  return historyAsync.when(
    data: (history) {
      if (history.isEmpty) {
        return const AsyncValue.data({
          'centerText': '0%',
          'statsThisWeek': null,
          'statsLastWeek': null,
          'distractingPercent': 0,
          'productivePercent': 0,
          'otherPercent': 0,
        });
      }

      final now = DateTime.now();
      final startOfThisWeek = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

      final thisWeekUsage = history.where((app) => app.date.isAfter(startOfThisWeek)).toList();
      final lastWeekUsage = history.where((app) => app.date.isAfter(startOfLastWeek) && app.date.isBefore(startOfThisWeek)).toList();

      ReportStats computeStats(List<AppUsage> list) {
        int productive = 0;
        int distracting = 0;
        int other = 0;
        for (var item in list) {
          if (item.category == AppCategory.productive) {
            productive += item.durationMinutes;
          } else if (item.category == AppCategory.distracting) {
            distracting += item.durationMinutes;
          } else {
            other += item.durationMinutes;
          }
        }
        return ReportStats(
          totalMinutes: productive + distracting + other,
          productiveMinutes: productive,
          distractingMinutes: distracting,
          otherMinutes: other,
        );
      }

      final statsThisWeek = computeStats(thisWeekUsage);
      final statsLastWeek = computeStats(lastWeekUsage);

      final distractingPercent = (statsThisWeek.distractingRatio * 100).round();
      final productivePercent = (statsThisWeek.productiveRatio * 100).round();
      final otherPercent = (100 - distractingPercent - productivePercent).clamp(0, 100);

      return AsyncValue.data({
        'centerText': '$distractingPercent%',
        'statsThisWeek': statsThisWeek,
        'statsLastWeek': statsLastWeek,
        'distractingPercent': distractingPercent,
        'productivePercent': productivePercent,
        'otherPercent': otherPercent,
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final monthlyAnalyticsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final historyAsync = ref.watch(usageHistoryProvider);

  return historyAsync.when(
    data: (history) {
      if (history.isEmpty) {
        return const AsyncValue.data({
          'centerText': '0%',
          'socialHoursStr': '0h',
          'productiveHoursStr': '0h',
          'otherHoursStr': '0h',
          'totalScreenTimeChange': '0h',
          'productiveTimeChange': '0h',
          'scoreImprovement': '0%',
        });
      }

      final now = DateTime.now();
      final startOfThisMonth = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
      final startOfLastMonth = startOfThisMonth.subtract(const Duration(days: 30));

      final thisMonthUsage = history.where((app) => app.date.isAfter(startOfThisMonth)).toList();
      final lastMonthUsage = history.where((app) => app.date.isAfter(startOfLastMonth) && app.date.isBefore(startOfThisMonth)).toList();
      
      int productive = 0, distracting = 0, other = 0;
      for (var item in thisMonthUsage) {
        if (item.category == AppCategory.productive) productive += item.durationMinutes;
        else if (item.category == AppCategory.distracting) distracting += item.durationMinutes;
        else other += item.durationMinutes;
      }
      final total = productive + distracting + other;
      final distractingPercent = total == 0 ? 0 : (distracting / total * 100).round();

      int lastProductive = 0, lastDistracting = 0, lastOther = 0;
      for (var item in lastMonthUsage) {
        if (item.category == AppCategory.productive) lastProductive += item.durationMinutes;
        else if (item.category == AppCategory.distracting) lastDistracting += item.durationMinutes;
        else lastOther += item.durationMinutes;
      }
      final lastTotal = lastProductive + lastDistracting + lastOther;

      String formatHours(int minutes) {
        final h = (minutes.abs()) ~/ 60;
        final m = (minutes.abs()) % 60;
        return h > 0 ? '${h}h ${m}m' : '${m}m';
      }

      final totalDiff = total - lastTotal;
      final prodDiff = productive - lastProductive;
      
      final currentProdRatio = total == 0 ? 0 : (productive / total * 100).round();
      final lastProdRatio = lastTotal == 0 ? 0 : (lastProductive / lastTotal * 100).round();
      final scoreDiff = currentProdRatio - lastProdRatio;

      final totalPrefix = totalDiff > 0 ? '+' : (totalDiff < 0 ? '−' : '');
      final prodPrefix = prodDiff > 0 ? '+' : (prodDiff < 0 ? '−' : '');
      final scorePrefix = scoreDiff > 0 ? '↑ ' : (scoreDiff < 0 ? '↓ ' : '= ');

      return AsyncValue.data({
        'centerText': '$distractingPercent%',
        'socialHoursStr': formatHours(distracting),
        'productiveHoursStr': formatHours(productive),
        'otherHoursStr': formatHours(other),
        'totalScreenTimeChange': '$totalPrefix${formatHours(totalDiff)}',
        'productiveTimeChange': '$prodPrefix${formatHours(prodDiff)}',
        'scoreImprovement': '$scorePrefix${scoreDiff.abs()}%',
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class DailyTrendItem {
  final String dayName;
  final int totalMinutes;
  final double heightFraction;

  DailyTrendItem({
    required this.dayName,
    required this.totalMinutes,
    required this.heightFraction,
  });
}

final sevenDayTrendProvider = Provider<AsyncValue<List<DailyTrendItem>>>((ref) {
  final historyAsync = ref.watch(usageHistoryProvider);

  return historyAsync.when(
    data: (history) {
      if (history.isEmpty) {
        return const AsyncValue.data([]);
      }

      final now = DateTime.now();
      final List<DailyTrendItem> trend = [];
      int maxMinutes = 1;

      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      // Extract past 7 days starting from 6 days ago up to today
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = weekdays[date.weekday - 1];
        
        final dailyTotal = history
            .where((app) => app.date.year == date.year && app.date.month == date.month && app.date.day == date.day)
            .fold(0, (sum, app) => sum + app.durationMinutes);
        
        if (dailyTotal > maxMinutes) {
          maxMinutes = dailyTotal;
        }

        trend.add(DailyTrendItem(
          dayName: dayName,
          totalMinutes: dailyTotal,
          heightFraction: 0.0, // populated in next loop
        ));
      }

      // Map heightFraction
      final normalizedTrend = trend.map((item) {
        return DailyTrendItem(
          dayName: item.dayName,
          totalMinutes: item.totalMinutes,
          heightFraction: (item.totalMinutes / maxMinutes).clamp(0.1, 1.0),
        );
      }).toList();

      return AsyncValue.data(normalizedTrend);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class AIInsightItem {
  final String emoji;
  final String title;
  final String description;

  AIInsightItem({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

final aiInsightsProvider = Provider<AsyncValue<List<AIInsightItem>>>((ref) {
  final historyAsync = ref.watch(usageHistoryProvider);
  final goalsAsync = ref.watch(dynamicGoalsProvider);

  return historyAsync.when(
    data: (history) {
      if (history.isEmpty) {
        return const AsyncValue.data([]);
      }

      final List<AIInsightItem> insights = [];

      // 1. Peak usage analysis
      final Map<int, int> hourlyDistracting = {};
      for (var app in history) {
        if (app.category == AppCategory.distracting) {
           final hour = app.date.hour;
           hourlyDistracting[hour] = (hourlyDistracting[hour] ?? 0) + app.durationMinutes;
        }
      }
      
      if (hourlyDistracting.isNotEmpty) {
        final peakHour = hourlyDistracting.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        final formatHour = (int h) => h == 0 ? '12am' : (h < 12 ? '${h}am' : (h == 12 ? '12pm' : '${h-12}pm'));
        insights.add(AIInsightItem(
          emoji: '🔴',
          title: 'Peak distraction: ${formatHour(peakHour)}',
          description: 'You tend to use social media most around this time. Try setting a focus blocker.',
        ));
      }

      // 2. Worst day analysis
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final List<int> weekdayTotals = List.filled(7, 0);
      final List<int> weekdayCounts = List.filled(7, 0);

      for (var app in history) {
        if (app.category == AppCategory.distracting) {
          final day = app.date.weekday - 1;
          weekdayTotals[day] += app.durationMinutes;
          weekdayCounts[day]++;
        }
      }

      int worstDayIdx = -1;
      double maxAvg = 0;
      for (int i = 0; i < 7; i++) {
        if (weekdayCounts[i] > 0) {
          final avg = weekdayTotals[i] / weekdayCounts[i];
          if (avg > maxAvg) {
            maxAvg = avg;
            worstDayIdx = i;
          }
        }
      }

      if (worstDayIdx != -1 && maxAvg > 0) {
        final hoursWorst = (maxAvg / 60).toStringAsFixed(1);
        insights.add(AIInsightItem(
          emoji: '⚡',
          title: '${weekdays[worstDayIdx]}s are distracting',
          description: '${hoursWorst}h avg social time. Focus on planning a specific tech-free schedule.',
        ));
      }

      // 3. Closest goal alert
      if (goalsAsync.isNotEmpty) {
        final activeGoals = goalsAsync.where((g) => g.category != 'screen_limit').toList();
        if (activeGoals.isNotEmpty) {
          activeGoals.sort((a, b) => b.progress.compareTo(a.progress));
          final target = activeGoals.first;
          if (target.progress > 0.0 && target.progress < 1.0) {
            insights.add(AIInsightItem(
              emoji: '🎯',
              title: '${target.title} is close!',
              description: 'You are at ${(target.progress * 100).round()}% for this skill today. Keep pushing!',
            ));
          } else if (target.progress >= 1.0) {
            insights.add(AIInsightItem(
              emoji: '🔥',
              title: 'Goal Crushers!',
              description: 'You\'ve completed your primary skill goals. Your focus stamina is improving.',
            ));
          }
        }
      }

      return AsyncValue.data(insights);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
