import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/enem_exam_model.dart';
import '../../models/enem_question_remote_model.dart';

// Bloco 1 - excecao especifica do datasource local.
// Usar uma excecao propria deixa claro que o erro veio dos assets/JSON do ENEM.
class EnemLocalDataSourceException implements Exception {
  // Bloco 2 - guarda a mensagem de erro.
  const EnemLocalDataSourceException(this.message);

  final String message;

  // Bloco 3 - formato amigavel quando o erro aparece em log/debug.
  @override
  String toString() => 'EnemLocalDataSourceException: $message';
}

// Bloco 4 - datasource local do ENEM.
// Ele substitui a API externa: todas as questoes vem dos arquivos em assets.
class EnemLocalDataSource {
  // Bloco 5 - permite trocar o AssetBundle em testes.
  // No app real, usa rootBundle automaticamente.
  const EnemLocalDataSource({
    AssetBundle? bundle,
    String basePath = 'assets/data/enem',
  })  : _bundle = bundle,
        _basePath = basePath;

  // Bloco 6 - bundle opcional injetado para teste.
  final AssetBundle? _bundle;

  // Bloco 7 - pasta base onde ficam index.json e enem_YYYY.json.
  final String _basePath;

  // Bloco 8 - se nao recebeu bundle, usa o bundle padrao do Flutter.
  AssetBundle get _assetBundle => _bundle ?? rootBundle;

  // Bloco 9 - lista as provas/anos disponiveis no index.json.
  Future<List<EnemExamModel>> listExams() async {
    // Bloco 10 - carrega o arquivo de indice.
    final decoded = await _loadMap('$_basePath/index.json');
    final exams = decoded['exams'];

    // Bloco 11 - valida se o campo exams e realmente uma lista.
    if (exams is! List) {
      throw const EnemLocalDataSourceException(
        'Indice local do ENEM invalido.',
      );
    }

    // Bloco 12 - converte cada item do JSON para EnemExamModel.
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
    // Bloco 13 - carrega o arquivo do ano especifico.
    final decoded = await _loadMap('$_basePath/enem_$year.json');
    final questions = decoded['questions'];

    // Bloco 14 - valida se existe lista de questoes.
    if (questions is! List) {
      throw EnemLocalDataSourceException(
        'Arquivo local do ENEM $year invalido.',
      );
    }

    // Bloco 15 - normaliza filtro de idioma, quando existir.
    final resolvedLanguage = language?.trim().toLowerCase();

    // Bloco 16 - transforma JSON bruto em models e aplica filtro de idioma.
    final parsed = questions
        .whereType<Map<String, dynamic>>()
        .map(EnemQuestionRemoteModel.fromMap)
        .where((question) {
      if (resolvedLanguage == null || resolvedLanguage.isEmpty) return true;
      return question.language == null ||
          question.language!.toLowerCase() == resolvedLanguage;
    }).toList(growable: false);

    // Bloco 17 - limit <= 0 significa carregar tudo.
    if (limit <= 0) return parsed;

    // Bloco 18 - quando limit e positivo, pega apenas as primeiras questoes.
    return parsed.take(limit).toList(growable: false);
  }

  // Bloco 19 - funcao privada para carregar e decodificar um JSON.
  Future<Map<String, dynamic>> _loadMap(String path) async {
    try {
      // Bloco 20 - le o asset como texto.
      final raw = await _assetBundle.loadString(path);

      // Bloco 21 - converte String JSON em Map/List do Dart.
      final decoded = jsonDecode(raw);

      // Bloco 22 - todos os arquivos esperados devem ter objeto na raiz.
      if (decoded is Map<String, dynamic>) return decoded;
      throw const EnemLocalDataSourceException(
        'JSON local do ENEM nao e um objeto.',
      );
    } on FlutterError catch (error) {
      // Bloco 23 - erro comum quando o asset nao foi declarado no pubspec.
      throw EnemLocalDataSourceException(
        'Asset local nao encontrado: $path (${error.message})',
      );
    } on FormatException catch (error) {
      // Bloco 24 - erro comum quando o JSON esta mal formatado.
      throw EnemLocalDataSourceException(
        'JSON local invalido em $path: ${error.message}',
      );
    }
  }
}
