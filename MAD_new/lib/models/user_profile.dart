class UserProfile {
  final String id;
  final String name;
  final String email;
  final String username;
  final String? profileImage;
  final String bio;
  final List<String> skills;
  final DateTime joinedDate;
  final int streaks;
  final int xpPoints;
  final int level;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.profileImage,
    required this.bio,
    required this.skills,
    required this.joinedDate,
    required this.streaks,
    required this.xpPoints,
    required this.level,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String id) {
    return UserProfile(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profileImage'],
      bio: json['bio'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      joinedDate: json['joinedDate'] != null 
          ? DateTime.parse(json['joinedDate']) 
          : DateTime.now(),
      streaks: json['streaks'] ?? 0,
      xpPoints: json['xpPoints'] ?? 0,
      level: json['level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'username': username,
      'profileImage': profileImage,
      'bio': bio,
      'skills': skills,
      'joinedDate': joinedDate.toIso8601String(),
      'streaks': streaks,
      'xpPoints': xpPoints,
      'level': level,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? profileImage,
    String? bio,
    List<String>? skills,
    DateTime? joinedDate,
    int? streaks,
    int? xpPoints,
    int? level,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      joinedDate: joinedDate ?? this.joinedDate,
      streaks: streaks ?? this.streaks,
      xpPoints: xpPoints ?? this.xpPoints,
      level: level ?? this.level,
    );
  }
}
