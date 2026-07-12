import '../../core/constants/db_constants.dart';
import '../../domain/entities/question.dart';

class QuestionModel extends Question {
  QuestionModel({
    super.id,
    required super.text,
    required super.subject,
    required super.topic,
    super.difficulty,
    super.year,
    super.examSource,
    required super.optionA,
    required super.optionB,
    required super.optionC,
    required super.optionD,
    super.optionE,
    required super.correctOption,
    super.explanation,
    super.imagePath,
    super.isFavorite,
    super.createdAt,
  });

  factory QuestionModel.fromEntity(Question question) {
    return QuestionModel(
      id: question.id,
      text: question.text,
      subject: question.subject,
      topic: question.topic,
      difficulty: question.difficulty,
      year: question.year,
      examSource: question.examSource,
      optionA: question.optionA,
      optionB: question.optionB,
      optionC: question.optionC,
      optionD: question.optionD,
      optionE: question.optionE,
      correctOption: question.correctOption,
      explanation: question.explanation,
      imagePath: question.imagePath,
      isFavorite: question.isFavorite,
      createdAt: question.createdAt,
    );
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: _asInt(map[DbConstants.colQuestionId]),
      text: (map[DbConstants.colQuestionText] as String?) ?? '',
      subject: (map[DbConstants.colQuestionSubject] as String?) ?? '',
      topic: (map[DbConstants.colQuestionTopic] as String?) ?? '',
      difficulty: _asInt(map[DbConstants.colQuestionDifficulty]) ?? 2,
      year: _asInt(map[DbConstants.colQuestionYear]),
      examSource: map[DbConstants.colQuestionExamSource] as String?,
      optionA: (map[DbConstants.colQuestionOptionA] as String?) ?? '',
      optionB: (map[DbConstants.colQuestionOptionB] as String?) ?? '',
      optionC: (map[DbConstants.colQuestionOptionC] as String?) ?? '',
      optionD: (map[DbConstants.colQuestionOptionD] as String?) ?? '',
      optionE: map[DbConstants.colQuestionOptionE] as String?,
      correctOption:
          ((map[DbConstants.colQuestionCorrectOption] as String?) ?? 'A')
              .trim()
              .toUpperCase(),
      explanation: map[DbConstants.colQuestionExplanation] as String?,
      imagePath: map[DbConstants.colQuestionImagePath] as String?,
      isFavorite: _asBool(map[DbConstants.colQuestionIsFavorite]),
      createdAt: _asDateTime(map[DbConstants.colQuestionCreatedAt]),
    );
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbConstants.colQuestionId: id,
      DbConstants.colQuestionText: text,
      DbConstants.colQuestionSubject: subject,
      DbConstants.colQuestionTopic: topic,
      DbConstants.colQuestionDifficulty: difficulty,
      DbConstants.colQuestionYear: year,
      DbConstants.colQuestionExamSource: examSource,
      DbConstants.colQuestionOptionA: optionA,
      DbConstants.colQuestionOptionB: optionB,
      DbConstants.colQuestionOptionC: optionC,
      DbConstants.colQuestionOptionD: optionD,
      DbConstants.colQuestionOptionE: optionE,
      DbConstants.colQuestionCorrectOption: normalizedCorrectOption,
      DbConstants.colQuestionExplanation: explanation,
      DbConstants.colQuestionImagePath: imagePath,
      DbConstants.colQuestionIsFavorite: isFavorite ? 1 : 0,
      DbConstants.colQuestionCreatedAt: createdAt.toIso8601String(),
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
