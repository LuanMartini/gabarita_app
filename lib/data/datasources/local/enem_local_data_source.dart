import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/enem_exam_model.dart';
import '../../models/enem_question_remote_model.dart';

class EnemLocalDataSourceException implements Exception {
  const EnemLocalDataSourceException(this.message);

  final String message;

  @override
  String toString() => 'EnemLocalDataSourceException: $message';
}

class EnemLocalDataSource {
  const EnemLocalDataSource({
    AssetBundle? bundle,
    String basePath = 'assets/data/enem',
  })  : _bundle = bundle,
        _basePath = basePath;

  final AssetBundle? _bundle;
  final String _basePath;

  AssetBundle get _assetBundle => _bundle ?? rootBundle;

  Future<List<EnemExamModel>> listExams() async {
    final decoded = await _loadMap('$_basePath/index.json');
    final exams = decoded['exams'];
    if (exams is! List) {
      throw const EnemLocalDataSourceException(
        'Indice local do ENEM invalido.',
      );
    }

    return exams
        .whereType<Map<String, dynamic>>()
        .map(EnemExamModel.fromMap)
        .where((exam) => exam.year > 0)
        .toList(growable: false);
  }

  Future<List<EnemQuestionRemoteModel>> loadQuestions({
    required int year,
    int limit = 0,
    String? language,
  }) async {
    final decoded = await _loadMap('$_basePath/enem_$year.json');
    final questions = decoded['questions'];
    if (questions is! List) {
      throw EnemLocalDataSourceException(
        'Arquivo local do ENEM $year invalido.',
      );
    }

    final resolvedLanguage = language?.trim().toLowerCase();
    final parsed = questions
        .whereType<Map<String, dynamic>>()
        .map(EnemQuestionRemoteModel.fromMap)
        .where((question) {
      if (resolvedLanguage == null || resolvedLanguage.isEmpty) return true;
      return question.language == null ||
          question.language!.toLowerCase() == resolvedLanguage;
    }).toList(growable: false);

    if (limit <= 0) return parsed;
    return parsed.take(limit).toList(growable: false);
  }

  Future<Map<String, dynamic>> _loadMap(String path) async {
    try {
      final raw = await _assetBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const EnemLocalDataSourceException(
        'JSON local do ENEM nao e um objeto.',
      );
    } on FlutterError catch (error) {
      throw EnemLocalDataSourceException(
        'Asset local nao encontrado: $path (${error.message})',
      );
    } on FormatException catch (error) {
      throw EnemLocalDataSourceException(
        'JSON local invalido em $path: ${error.message}',
      );
    }
  }
}
