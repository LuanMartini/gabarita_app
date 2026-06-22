enum StudySessionType {
  free,
  simulado,
  review,
  dailyChallenge,
}

class StudySession {
  StudySession({
    required this.id,
    required this.userId,
    this.type = StudySessionType.free,
    this.subjects = const [],
    this.totalQuestions = 0,
    this.correctCount = 0,
    this.durationSeconds = 0,
    this.latitude,
    this.longitude,
    this.locationName,
    DateTime? startedAt,
    this.finishedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  final String id;
  final int userId;
  final StudySessionType type;
  final List<String> subjects;
  final int totalQuestions;
  final int correctCount;
  final int durationSeconds;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime startedAt;
  final DateTime? finishedAt;

  double get accuracyRate {
    if (totalQuestions == 0) return 0;
    return correctCount / totalQuestions;
  }

  int get wrongCount => totalQuestions - correctCount;

  int get scorePercentage => (accuracyRate * 100).round();

  bool get isFinished => finishedAt != null;

  StudySession copyWith({
    String? id,
    int? userId,
    StudySessionType? type,
    List<String>? subjects,
    int? totalQuestions,
    int? correctCount,
    int? durationSeconds,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      subjects: subjects ?? this.subjects,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}
