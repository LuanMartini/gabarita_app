import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/enem_exam_model.dart';
import '../../models/enem_question_remote_model.dart';

class EnemApiException implements Exception {
  const EnemApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return 'EnemApiException$code: $message';
  }
}

class EnemApiClient {
  EnemApiClient({
    http.Client? client,
    Uri? baseUri,
  })  : _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse('https://api.enem.dev/v1');

  final http.Client _client;
  final Uri _baseUri;

  Future<List<EnemExamModel>> listExams() async {
    final response =
        await _get(_baseUri.replace(path: '${_baseUri.path}/exams'));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const EnemApiException('Resposta invalida ao listar provas.');
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
    final queryParameters = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (language != null && language.isNotEmpty) 'language': language,
    };
    final uri = _baseUri.replace(
      path: '${_baseUri.path}/exams/$year/questions',
      queryParameters: queryParameters,
    );
    final response = await _get(uri);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const EnemApiException('Resposta invalida ao listar questoes.');
    }

    return EnemQuestionsPage.fromMap(decoded);
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

  Future<http.Response> _get(Uri uri) async {
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EnemApiException(
        'Falha ao acessar a API ENEM.',
        statusCode: response.statusCode,
      );
    }
    return response;
  }
}
