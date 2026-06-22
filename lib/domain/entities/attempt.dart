class Attempt {
  Attempt({
    this.id,
    required this.userId,
    required this.questionId,
    required this.sessionId,
    required this.selectedOption,
    required this.isCorrect,
    this.timeTakenSeconds = 0,
    this.latitude,
    this.longitude,
    this.locationName,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  final int? id;
  final int userId;
  final int questionId;
  final String sessionId;
  final String selectedOption;
  final bool isCorrect;
  final int timeTakenSeconds;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime answeredAt;

  Attempt copyWith({
    int? id,
    int? userId,
    int? questionId,
    String? sessionId,
    String? selectedOption,
    bool? isCorrect,
    int? timeTakenSeconds,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? answeredAt,
  }) {
    return Attempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      sessionId: sessionId ?? this.sessionId,
      selectedOption: selectedOption ?? this.selectedOption,
      isCorrect: isCorrect ?? this.isCorrect,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}
