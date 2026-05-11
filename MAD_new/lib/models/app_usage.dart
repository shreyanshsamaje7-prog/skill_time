enum AppCategory { productive, neutral, distracting }

class AppUsage {
  final String id;
  final String userId;
  final String packageName;
  final String appName;
  final AppCategory category;
  final int durationMinutes;
  final DateTime date;

  AppUsage({
    required this.id,
    required this.userId,
    required this.packageName,
    required this.appName,
    required this.category,
    required this.durationMinutes,
    required this.date,
  });

  factory AppUsage.fromJson(Map<String, dynamic> json, String id) {
    return AppUsage(
      id: id,
      userId: json['userId'] ?? '',
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      category: AppCategory.values.firstWhere(
        (e) => e.name == (json['category'] ?? 'neutral'),
        orElse: () => AppCategory.neutral,
      ),
      durationMinutes: json['durationMinutes'] ?? 0,
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'packageName': packageName,
      'appName': appName,
      'category': category.name,
      'durationMinutes': durationMinutes,
      'date': date.toIso8601String(),
    };
  }
}
