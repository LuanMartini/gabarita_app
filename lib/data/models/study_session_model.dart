import 'dart:convert';

import '../../core/constants/db_constants.dart';
import '../../domain/entities/study_session.dart';

class StudySessionModel extends StudySession {
  StudySessionModel({
    required super.id,
    required super.userId,
    super.type,
    super.subjects,
    super.totalQuestions,
    super.correctCount,
    super.durationSeconds,
    super.latitude,
    super.longitude,
    super.locationName,
    super.startedAt,
    super.finishedAt,
  });

  factory StudySessionModel.fromEntity(StudySession session) {
    return StudySessionModel(
      id: session.id,
      userId: session.userId,
      type: session.type,
      subjects: session.subjects,
      totalQuestions: session.totalQuestions,
      correctCount: session.correctCount,
      durationSeconds: session.durationSeconds,
      latitude: session.latitude,
      longitude: session.longitude,
      locationName: session.locationName,
      startedAt: session.startedAt,
      finishedAt: session.finishedAt,
    );
  }

  factory StudySessionModel.fromMap(Map<String, dynamic> map) {
    return StudySessionModel(
      id: (map[DbConstants.colSessionId] as String?) ?? '',
      userId: _asInt(map[DbConstants.colSessionUserId]) ?? 0,
      type: _asSessionType(map[DbConstants.colSessionType]),
      subjects: _asStringList(map[DbConstants.colSessionSubjectsJson]),
      totalQuestions: _asInt(map[DbConstants.colSessionTotalQuestions]) ?? 0,
      correctCount: _asInt(map[DbConstants.colSessionCorrectCount]) ?? 0,
      durationSeconds: _asInt(map[DbConstants.colSessionDurationSeconds]) ?? 0,
      latitude: _asDouble(map[DbConstants.colSessionLatitude]),
      longitude: _asDouble(map[DbConstants.colSessionLongitude]),
      locationName: map[DbConstants.colSessionLocationName] as String?,
      startedAt: _asDateTime(map[DbConstants.colSessionStartedAt]),
      finishedAt: _asNullableDateTime(map[DbConstants.colSessionFinishedAt]),
    );
  }

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    return StudySessionModel.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colSessionId: id,
      DbConstants.colSessionUserId: userId,
      DbConstants.colSessionType: type.name,
      DbConstants.colSessionSubjectsJson: jsonEncode(subjects),
      DbConstants.colSessionTotalQuestions: totalQuestions,
      DbConstants.colSessionCorrectCount: correctCount,
      DbConstants.colSessionDurationSeconds: durationSeconds,
      DbConstants.colSessionLatitude: latitude,
      DbConstants.colSessionLongitude: longitude,
      DbConstants.colSessionLocationName: locationName,
      DbConstants.colSessionStartedAt: startedAt.toIso8601String(),
      DbConstants.colSessionFinishedAt: finishedAt?.toIso8601String(),
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

DateTime _asDateTime(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

DateTime? _asNullableDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

StudySessionType _asSessionType(Object? value) {
  final raw = value?.toString();
  return StudySessionType.values.firstWhere(
    (type) => type.name == raw,
    orElse: () => StudySessionType.free,
  );
}

List<String> _asStringList(Object? value) {
  if (value == null) return const [];
  if (value is List) return value.map((item) => item.toString()).toList();
  try {
    final decoded = jsonDecode(value.toString());
    if (decoded is List) {
      return decoded.map((item) => item.toString()).toList();
    }
  } catch (_) {
    return const [];
  }
  return const [];
}
