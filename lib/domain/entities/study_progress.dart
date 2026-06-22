class StudyProgress {
  const StudyProgress({
    required this.currentStreak,
    required this.maxStreak,
    required this.weeklyGoalQuestions,
    required this.weeklyAnsweredQuestions,
    this.lastStudyDate,
    this.weekStartedAt,
  });

  factory StudyProgress.initial() {
    return const StudyProgress(
      currentStreak: 0,
      maxStreak: 0,
      weeklyGoalQuestions: 50,
      weeklyAnsweredQuestions: 0,
    );
  }

  final int currentStreak;
  final int maxStreak;
  final int weeklyGoalQuestions;
  final int weeklyAnsweredQuestions;
  final DateTime? lastStudyDate;
  final DateTime? weekStartedAt;

  double get weeklyProgressRate {
    if (weeklyGoalQuestions <= 0) return 0;
    return (weeklyAnsweredQuestions / weeklyGoalQuestions)
        .clamp(0, 1)
        .toDouble();
  }

  int get remainingWeeklyQuestions {
    final remaining = weeklyGoalQuestions - weeklyAnsweredQuestions;
    return remaining < 0 ? 0 : remaining;
  }

  StudyProgress copyWith({
    int? currentStreak,
    int? maxStreak,
    int? weeklyGoalQuestions,
    int? weeklyAnsweredQuestions,
    DateTime? lastStudyDate,
    DateTime? weekStartedAt,
  }) {
    return StudyProgress(
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      weeklyGoalQuestions: weeklyGoalQuestions ?? this.weeklyGoalQuestions,
      weeklyAnsweredQuestions:
          weeklyAnsweredQuestions ?? this.weeklyAnsweredQuestions,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      weekStartedAt: weekStartedAt ?? this.weekStartedAt,
    );
  }
}
