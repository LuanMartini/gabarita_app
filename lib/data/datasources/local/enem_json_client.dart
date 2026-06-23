import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/enem_exam_model.dart';
import '../../models/enem_question_remote_model.dart';

class EnemJsonException implements Exception {
  const EnemJsonException(this.message);

  final String message;

  @override
  String toString() {
    return 'EnemJsonException: $message';
  }
}

class EnemJsonClient {
  EnemJsonClient({
    AssetBundle? assetBundle,
    String assetsBasePath = 'assets/data',
  })  : _assetBundle = assetBundle ?? rootBundle,
        _assetsBasePath = assetsBasePath;

  final AssetBundle _assetBundle;
  final String _assetsBasePath;

  Future<List<EnemExamModel>> listExams() async {
    final decoded = await _loadJson('$_assetsBasePath/enem_exams.json');
    if (decoded is! List) {
      throw const EnemJsonException('JSON local invalido ao listar provas.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(EnemExamModel.fromMap)
        .where((exam) => exam.year > 0)
        .toList(growable: false);
  }

  Future<EnemQuestionsPage> listQuestions({
    required int year,
    int limit = 40,
    int offset = 0,
    String? language,
  }) async {
    final decoded = await _loadQuestionsJson(year: year, language: language);
    final rawQuestions = _readQuestionList(decoded);
    final safeOffset = offset.clamp(0, rawQuestions.length).toInt();
    final safeLimit = limit.clamp(1, 100).toInt();
    final end = (safeOffset + safeLimit).clamp(0, rawQuestions.length).toInt();
    final pageQuestions = rawQuestions.sublist(safeOffset, end);

    return EnemQuestionsPage.fromMap({
      'metadata': {
        'limit': safeLimit,
        'offset': safeOffset,
        'total': rawQuestions.length,
        'hasMore': end < rawQuestions.length,
      },
      'questions': pageQuestions,
    });
  }

  Future<List<EnemQuestionRemoteModel>> fetchQuestions({
    required int year,
    int maxQuestions = 40,
    String? language,
  }) async {
    final pageSize = maxQuestions.clamp(1, 100).toInt();
    var offset = 0;
    final questions = <EnemQuestionRemoteModel>[];

    while (questions.length < maxQuestions) {
      final page = await listQuestions(
        year: year,
        limit: pageSize,
        offset: offset,
        language: language,
      );

      questions.addAll(page.questions);
      if (!page.hasMore || page.questions.isEmpty) break;
      offset += page.limit <= 0 ? page.questions.length : page.limit;
    }

    return questions.take(maxQuestions).toList(growable: false);
  }

  Future<Object?> _loadQuestionsJson({
    required int year,
    String? language,
  }) async {
    final normalizedLanguage = language?.trim();
    if (normalizedLanguage != null && normalizedLanguage.isNotEmpty) {
      try {
        return await _loadJson(
          '$_assetsBasePath/enem_questions_${year}_$normalizedLanguage.json',
        );
      } on EnemJsonException {
        // Fallback para o arquivo anual quando nao ha JSON por idioma.
      }
    }

    return _loadJson('$_assetsBasePath/enem_questions_$year.json');
  }

  Future<Object?> _loadJson(String path) async {
    try {
      final source = await _assetBundle.loadString(path);
      return jsonDecode(source);
    } on FlutterError catch (error) {
      throw EnemJsonException('JSON local nao encontrado: $path. $error');
    } on FormatException catch (error) {
      throw EnemJsonException('JSON local invalido: $path. $error');
    }
  }

  List<Map<String, dynamic>> _readQuestionList(Object? decoded) {
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (decoded is Map<String, dynamic>) {
      final rawQuestions = decoded['questions'];
      if (rawQuestions is List) {
        return rawQuestions
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
    }
    throw const EnemJsonException('JSON local invalido ao listar questoes.');
  }
}
