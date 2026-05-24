class FocusSession {
  final String id;
  final String userId;
  final String skill; // e.g. 'Reading', 'Coding', 'Vocabulary'
  final int durationMinutes;
  final DateTime date;
  final bool completed;

  FocusSession({
    required this.id,
    required this.userId,
    required this.skill,
    required this.durationMinutes,
    required this.date,
    this.completed = true,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json, String id) {
    return FocusSession(
      id: id,
      userId: json['userId'] ?? '',
      skill: json['skill'] ?? 'General Focus',
      durationMinutes: json['durationMinutes'] ?? 0,
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      completed: json['completed'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'skill': skill,
      'durationMinutes': durationMinutes,
      'date': date.toIso8601String(),
      'completed': completed,
    };
  }
}
