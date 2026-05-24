import '../models/achievement.dart';

class DomainAchievementsService {
  static List<Achievement> getAchievementsForInterests(List<String> interests) {
    final List<Achievement> domainAchievements = [];

    for (var interest in interests) {
      switch (interest.toLowerCase()) {
        case 'coding':
          domainAchievements.addAll([
            Achievement(
              id: 'coding_night_coder',
              title: 'Night Coder',
              description: 'Focus on coding after 8 PM',
              icon: '🌙',
              xpReward: 150,
            ),
            Achievement(
              id: 'coding_debug_warrior',
              title: 'Debug Warrior',
              description: 'Maintain a 3-day coding streak',
              icon: '⚔️',
              xpReward: 200,
            ),
          ]);
          break;
        case 'ai/ml':
          domainAchievements.addAll([
            Achievement(
              id: 'ai_neural_explorer',
              title: 'Neural Explorer',
              description: 'Complete 5 AI/ML focus sessions',
              icon: '🧠',
              xpReward: 250,
            ),
            Achievement(
              id: 'ai_model_builder',
              title: 'Model Builder',
              description: 'Maintain a 5-day AI learning streak',
              icon: '🤖',
              xpReward: 300,
            ),
          ]);
          break;
        case 'cybersecurity':
          domainAchievements.addAll([
            Achievement(
              id: 'cyber_threat_hunter',
              title: 'Threat Hunter',
              description: 'Complete 3 security challenges',
              icon: '🛡️',
              xpReward: 200,
            ),
            Achievement(
              id: 'cyber_midnight_defender',
              title: 'Midnight Defender',
              description: 'Focus on cybersecurity past midnight',
              icon: '🦇',
              xpReward: 250,
            ),
          ]);
          break;
        case 'fitness':
          domainAchievements.addAll([
            Achievement(
              id: 'fitness_focus_athlete',
              title: 'Focus Athlete',
              description: 'Take 5 healthy screen breaks',
              icon: '🏃',
              xpReward: 150,
            ),
            Achievement(
              id: 'fitness_healthy_balance',
              title: 'Healthy Balance Badge',
              description: 'Balance work and physical activity for a week',
              icon: '⚖️',
              xpReward: 200,
            ),
          ]);
          break;
        case 'reading':
          domainAchievements.addAll([
            Achievement(
              id: 'reading_knowledge_monk',
              title: 'Knowledge Monk',
              description: 'Read for 2 hours uninterrupted',
              icon: '📖',
              xpReward: 150,
            ),
            Achievement(
              id: 'reading_deep_reader',
              title: 'Deep Reader',
              description: 'Maintain a 7-day reading streak',
              icon: '📚',
              xpReward: 300,
            ),
          ]);
          break;
        default:
          domainAchievements.addAll([
            Achievement(
              id: '${interest.toLowerCase().replaceAll(' ', '_')}_starter',
              title: '$interest Starter',
              description: 'Begin your journey in $interest',
              icon: '🚀',
              xpReward: 100,
            ),
            Achievement(
              id: '${interest.toLowerCase().replaceAll(' ', '_')}_master',
              title: '$interest Master',
              description: 'Reach a 7-day streak in $interest',
              icon: '👑',
              xpReward: 300,
            ),
          ]);
      }
    }

    return domainAchievements;
  }
}
