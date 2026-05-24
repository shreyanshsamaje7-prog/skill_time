import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'dart:math';

class Insight {
  final String title;
  final String description;
  final String icon;

  Insight({
    required this.title,
    required this.description,
    required this.icon,
  });
}

final recommendationProvider = Provider<List<Insight>>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  
  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile == null || profile.interests.isEmpty) {
        return [
          Insight(
            title: 'Set up your interests',
            description: 'Tell us what you want to learn to get personalized recommendations.',
            icon: '🎯',
          ),
        ];
      }

      final List<Insight> insights = [];
      final random = Random();

      for (var interest in profile.interests) {
        switch (interest.toLowerCase()) {
          case 'coding':
            insights.add(Insight(
              title: 'Coding Focus',
              description: '2 hours distraction-free coding today',
              icon: '💻',
            ));
            break;
          case 'ai/ml':
            insights.add(Insight(
              title: 'Neural Learning',
              description: 'Best focus time detected for AI learning',
              icon: '🤖',
            ));
            break;
          case 'cybersecurity':
            insights.add(Insight(
              title: 'Security Active',
              description: 'Night focus sessions improved',
              icon: '🛡️',
            ));
            break;
          case 'fitness':
            insights.add(Insight(
              title: 'Healthy Balance',
              description: 'Balance focus with movement',
              icon: '💪',
            ));
            break;
          case 'reading':
            insights.add(Insight(
              title: 'Deep Reading',
              description: 'Maintain your reading streak',
              icon: '📚',
            ));
            break;
          case 'design':
          case 'ui/ux':
            insights.add(Insight(
              title: 'Creative Mode',
              description: 'Craft some pixels without distractions',
              icon: '✨',
            ));
            break;
          case 'productivity':
            insights.add(Insight(
              title: 'Deep Work',
              description: 'Your focus consistency improved 32%',
              icon: '⚡',
            ));
            break;
          default:
            insights.add(Insight(
              title: '$interest Mastery',
              description: 'Stay focused on your $interest goals today',
              icon: '⭐',
            ));
        }
      }

      // Shuffle and pick top 3
      insights.shuffle(random);
      return insights.take(3).toList();
    },
    orElse: () => [],
  );
});
