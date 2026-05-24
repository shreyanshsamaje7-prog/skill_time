class Goal {
  final String id;
  final String userId;
  final String title;
  final String emoji;
  final String category; // 'screen_limit' or 'skill_growth'
  final int targetMinutes;
  final int currentMinutes;
  final int streak;
  final String status;
  final DateTime? lastCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.emoji,
    required this.category,
    required this.targetMinutes,
    required this.currentMinutes,
    required this.streak,
    required this.status,
    this.lastCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json, String id) {
    return Goal(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      emoji: json['emoji'] ?? '🎯',
      category: json['category'] ?? 'skill_growth',
      targetMinutes: json['targetMinutes'] ?? 0,
      currentMinutes: json['currentMinutes'] ?? 0,
      streak: json['streak'] ?? 0,
      status: json['status'] ?? 'In progress',
      lastCompleted: json['lastCompleted'] != null 
          ? DateTime.parse(json['lastCompleted']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'emoji': emoji,
      'category': category,
      'targetMinutes': targetMinutes,
      'currentMinutes': currentMinutes,
      'streak': streak,
      'status': status,
      'lastCompleted': lastCompleted?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? emoji,
    String? category,
    int? targetMinutes,
    int? currentMinutes,
    int? streak,
    String? status,
    DateTime? lastCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      currentMinutes: currentMinutes ?? this.currentMinutes,
      streak: streak ?? this.streak,
      status: status ?? this.status,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  double get progress {
    if (targetMinutes == 0) return 0.0;
    if (category == 'screen_limit') {
      // Screen limit goal: progress is 1.0 (limit not reached) down to 0.0 (over limit)
      // Or we can show progress as how much of the allowed limit has been used:
      return (currentMinutes / targetMinutes).clamp(0.0, 1.0);
    }
    return (currentMinutes / targetMinutes).clamp(0.0, 1.0);
  }
}
