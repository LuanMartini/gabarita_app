import '../../core/constants/db_constants.dart';
import '../../domain/entities/attempt.dart';

class AttemptModel extends Attempt {
  AttemptModel({
    super.id,
    required super.userId,
    required super.questionId,
    required super.sessionId,
    required super.selectedOption,
    required super.isCorrect,
    super.timeTakenSeconds,
    super.latitude,
    super.longitude,
    super.locationName,
    super.answeredAt,
  });

  factory AttemptModel.fromEntity(Attempt attempt) {
    return AttemptModel(
      id: attempt.id,
      userId: attempt.userId,
      questionId: attempt.questionId,
      sessionId: attempt.sessionId,
      selectedOption: attempt.selectedOption,
      isCorrect: attempt.isCorrect,
      timeTakenSeconds: attempt.timeTakenSeconds,
      latitude: attempt.latitude,
      longitude: attempt.longitude,
      locationName: attempt.locationName,
      answeredAt: attempt.answeredAt,
    );
  }

  factory AttemptModel.fromMap(Map<String, dynamic> map) {
    return AttemptModel(
      id: _asInt(map[DbConstants.colAttemptId]),
      userId: _asInt(map[DbConstants.colAttemptUserId]) ?? 0,
      questionId: _asInt(map[DbConstants.colAttemptQuestionId]) ?? 0,
      sessionId: (map[DbConstants.colAttemptSessionId] as String?) ?? '',
      selectedOption:
          ((map[DbConstants.colAttemptSelectedOption] as String?) ?? '')
              .toUpperCase(),
      isCorrect: _asBool(map[DbConstants.colAttemptIsCorrect]),
      timeTakenSeconds:
          _asInt(map[DbConstants.colAttemptTimeTakenSeconds]) ?? 0,
      latitude: _asDouble(map[DbConstants.colAttemptLatitude]),
      longitude: _asDouble(map[DbConstants.colAttemptLongitude]),
      locationName: map[DbConstants.colAttemptLocationName] as String?,
      answeredAt: _asDateTime(map[DbConstants.colAttemptAnsweredAt]),
    );
  }

  factory AttemptModel.fromJson(Map<String, dynamic> json) {
    return AttemptModel.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbConstants.colAttemptId: id,
      DbConstants.colAttemptUserId: userId,
      DbConstants.colAttemptQuestionId: questionId,
      DbConstants.colAttemptSessionId: sessionId,
      DbConstants.colAttemptSelectedOption: selectedOption.toUpperCase(),
      DbConstants.colAttemptIsCorrect: isCorrect ? 1 : 0,
      DbConstants.colAttemptTimeTakenSeconds: timeTakenSeconds,
      DbConstants.colAttemptLatitude: latitude,
      DbConstants.colAttemptLongitude: longitude,
      DbConstants.colAttemptLocationName: locationName,
      DbConstants.colAttemptAnsweredAt: answeredAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _asBool(Object? value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

DateTime _asDateTime(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
