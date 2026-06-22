class User {
  User({
    this.id,
    required this.name,
    this.avatar,
    DateTime? createdAt,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.totalAnswered = 0,
    this.totalCorrect = 0,
    this.studyGoalMinutes = 30,
    this.notificationsEnabled = true,
    this.notificationHour = 19,
    this.notificationMinute = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String name;
  final String? avatar;
  final DateTime createdAt;
  final int currentStreak;
  final int maxStreak;
  final int totalAnswered;
  final int totalCorrect;
  final int studyGoalMinutes;
  final bool notificationsEnabled;
  final int notificationHour;
  final int notificationMinute;

  double get accuracyRate {
    if (totalAnswered == 0) return 0;
    return totalCorrect / totalAnswered;
  }

  User copyWith({
    int? id,
    String? name,
    String? avatar,
    DateTime? createdAt,
    int? currentStreak,
    int? maxStreak,
    int? totalAnswered,
    int? totalCorrect,
    int? studyGoalMinutes,
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      studyGoalMinutes: studyGoalMinutes ?? this.studyGoalMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
    );
  }
}
