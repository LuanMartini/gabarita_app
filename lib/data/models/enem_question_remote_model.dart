import '../../domain/entities/question.dart';
import '../../domain/services/question_quality_policy.dart';

// Bloco 1 - modelo de pagina de questoes.
// Foi mantido porque alguns formatos de JSON/API usam metadata + questions.
class EnemQuestionsPage {
  // Bloco 2 - construtor com metadados de paginacao.
  const EnemQuestionsPage({
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
    required this.questions,
  });

  // Bloco 3 - cria uma pagina a partir de um Map do JSON.
  factory EnemQuestionsPage.fromMap(Map<String, dynamic> map) {
    // Bloco 4 - metadata pode ou nao existir; se nao existir, usa mapa vazio.
    final metadata = map['metadata'];
    final rawQuestions = map['questions'];
    final meta =
        metadata is Map<String, dynamic> ? metadata : const <String, dynamic>{};

    // Bloco 5 - converte metadados e lista de questoes.
    return EnemQuestionsPage(
      limit: _asInt(meta['limit']) ?? 0,
      offset: _asInt(meta['offset']) ?? 0,
      total: _asInt(meta['total']) ?? 0,
      hasMore: _asBool(meta['hasMore']),
      questions: rawQuestions is List
          ? rawQuestions
              .whereType<Map<String, dynamic>>()
              .map(EnemQuestionRemoteModel.fromMap)
              .toList(growable: false)
          : const <EnemQuestionRemoteModel>[],
    );
  }

  // Bloco 6 - quantidade solicitada.
  final int limit;

  // Bloco 7 - deslocamento da pagina.
  final int offset;

  // Bloco 8 - total informado pela fonte.
  final int total;

  // Bloco 9 - indica se haveria proxima pagina.
  final bool hasMore;

  // Bloco 10 - questoes convertidas para modelo intermediario.
  final List<EnemQuestionRemoteModel> questions;
}

// Bloco 11 - modelo intermediario da questao do ENEM.
// O nome "Remote" ficou por compatibilidade, mas hoje ele tambem representa
// questoes vindas do JSON offline.
class EnemQuestionRemoteModel {
  // Bloco 12 - construtor espelhando os campos do JSON.
  const EnemQuestionRemoteModel({
    required this.title,
    required this.index,
    required this.year,
    required this.correctAlternative,
    required this.alternatives,
    this.discipline,
    this.language,
    this.context,
    this.alternativesIntroduction,
    this.files = const <String>[],
  });

  // Bloco 13 - cria o model a partir de um Map do JSON.
  factory EnemQuestionRemoteModel.fromMap(Map<String, dynamic> map) {
    // Bloco 14 - alternativas e arquivos chegam como listas dinamicas.
    final rawAlternatives = map['alternatives'];
    final rawFiles = map['files'];

    // Bloco 15 - converte cada campo protegendo contra null/tipos inesperados.
    return EnemQuestionRemoteModel(
      title: map['title']?.toString() ?? '',
      index: _asInt(map['index']) ?? 0,
      discipline: map['discipline']?.toString(),
      language: map['language']?.toString(),
      year: _asInt(map['year']) ?? 0,
      context: map['context']?.toString(),
      files: rawFiles is List
          ? rawFiles.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      correctAlternative:
          (map['correctAlternative']?.toString() ?? '').trim().toUpperCase(),
      alternativesIntroduction: map['alternativesIntroduction']?.toString(),
      alternatives: rawAlternatives is List
          ? rawAlternatives
              .whereType<Map<String, dynamic>>()
              .map(EnemAlternativeRemoteModel.fromMap)
              .toList(growable: false)
          : const <EnemAlternativeRemoteModel>[],
    );
  }

  // Bloco 16 - titulo/identificacao da questao.
  final String title;

  // Bloco 17 - numero da questao dentro da prova.
  final int index;

  // Bloco 18 - disciplina bruta do JSON.
  final String? discipline;

  // Bloco 19 - idioma quando a questao e de lingua estrangeira.
  final String? language;

  // Bloco 20 - ano da prova.
  final int year;

  // Bloco 21 - texto base/enunciado.
  final String? context;

  // Bloco 22 - arquivos/imagens associados a questao.
  final List<String> files;

  // Bloco 23 - alternativa correta oficial.
  final String correctAlternative;

  // Bloco 24 - texto que introduz as alternativas.
  final String? alternativesIntroduction;

  // Bloco 25 - lista de alternativas.
  final List<EnemAlternativeRemoteModel> alternatives;

  // Bloco 26 - decide se esta questao pode virar Question no app.
  // A regra remove questoes incompletas e questoes que dependem de imagem.
  bool get canBecomeQuestion {
    return _hasTextualStatement &&
        year > 0 &&
        index > 0 &&
        discipline?.trim().isNotEmpty == true &&
        _hasCompleteAlternatives &&
        !requiresVisualResource;
  }

  // Bloco 27 - detecta dependencia visual.
  // Se precisa de imagem/grafico, o app descarta porque o requisito e offline
  // com questoes sem imagem.
  bool get requiresVisualResource {
    return QuestionQualityPolicy.hasVisualDependency(
      textBlocks: _textBlocks,
      files: <String?>[
        ...files,
        ...alternatives.map((alternative) => alternative.file),
      ],
    );
  }

  // Bloco 28 - converte o model intermediario na entidade pura Question.
  Question toQuestion() {
    // Bloco 29 - organiza alternativas por letra para preencher A/B/C/D/E.
    final byLetter = <String, EnemAlternativeRemoteModel>{
      for (final alternative in alternatives) alternative.letter: alternative,
    };

    // Bloco 30 - junta enunciado e introducao das alternativas.
    final statementBlocks = <String>[
      if (context != null && context!.trim().isNotEmpty) context!.trim(),
      if (alternativesIntroduction != null &&
          alternativesIntroduction!.trim().isNotEmpty)
        alternativesIntroduction!.trim(),
    ];

    // Bloco 31 - monta a entidade usada pelo resto do app.
    return Question(
      text: statementBlocks.isEmpty ? title : statementBlocks.join('\n\n'),
      subject: _disciplineLabel(discipline),
      topic: _topicLabel,
      difficulty: 2,
      year: year,
      examSource: 'ENEM $year',
      optionA: byLetter['A']?.text.trim() ?? '',
      optionB: byLetter['B']?.text.trim() ?? '',
      optionC: byLetter['C']?.text.trim() ?? '',
      optionD: byLetter['D']?.text.trim() ?? '',
      optionE: byLetter['E']?.text.trim(),
      correctOption: correctAlternative,
      explanation: 'Gabarito oficial: alternativa $correctAlternative.',
      imagePath: null,
    );
  }

  // Bloco 32 - precisa ter texto suficiente para aparecer na tela.
  bool get _hasTextualStatement {
    return context?.trim().isNotEmpty == true ||
        alternativesIntroduction?.trim().isNotEmpty == true;
  }

  // Bloco 33 - valida se existem A, B, C, D e E com texto e gabarito valido.
  bool get _hasCompleteAlternatives {
    const expectedLetters = <String>{'A', 'B', 'C', 'D', 'E'};
    final alternativesByLetter = <String, EnemAlternativeRemoteModel>{
      for (final alternative in alternatives) alternative.letter: alternative,
    };

    return alternatives.length == expectedLetters.length &&
        alternativesByLetter.length == expectedLetters.length &&
        alternativesByLetter.keys.toSet().containsAll(expectedLetters) &&
        alternativesByLetter.values.every(
          (alternative) => alternative.text.trim().isNotEmpty,
        ) &&
        expectedLetters.contains(correctAlternative);
  }

  // Bloco 34 - todos os textos usados pela politica de qualidade.
  Iterable<String> get _textBlocks sync* {
    yield title;
    if (context != null) yield context!;
    if (alternativesIntroduction != null) {
      yield alternativesIntroduction!;
    }
    for (final alternative in alternatives) {
      yield alternative.text;
    }
  }

  // Bloco 35 - topico exibido na UI.
  String get _topicLabel {
    if (language == null || language!.isEmpty) return title;
    return '$title - ${language!}';
  }
}

// Bloco 36 - modelo intermediario de alternativa do ENEM.
class EnemAlternativeRemoteModel {
  // Bloco 37 - construtor da alternativa.
  const EnemAlternativeRemoteModel({
    required this.letter,
    required this.text,
    required this.isCorrect,
    this.file,
  });

  // Bloco 38 - cria alternativa a partir do Map do JSON.
  factory EnemAlternativeRemoteModel.fromMap(Map<String, dynamic> map) {
    return EnemAlternativeRemoteModel(
      letter: (map['letter']?.toString() ?? '').trim().toUpperCase(),
      text: map['text']?.toString() ?? '',
      file: map['file']?.toString(),
      isCorrect: _asBool(map['isCorrect']),
    );
  }

  // Bloco 39 - letra A/B/C/D/E.
  final String letter;

  // Bloco 40 - texto da alternativa.
  final String text;

  // Bloco 41 - arquivo/imagem da alternativa, quando existir.
  final String? file;

  // Bloco 42 - booleano vindo da fonte original.
  final bool isCorrect;
}

// Bloco 43 - converte codigo de disciplina do JSON para texto amigavel.
String _disciplineLabel(String? value) {
  switch (value) {
    case 'matematica':
      return 'Matematica';
    case 'ciencias-natureza':
      return 'Ciencias da Natureza';
    case 'ciencias-humanas':
      return 'Ciencias Humanas';
    case 'linguagens':
      return 'Linguagens';
    default:
      return value ?? 'ENEM';
  }
}

// Bloco 44 - conversao segura para int.
int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

// Bloco 45 - conversao segura para bool.
bool _asBool(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value.toString().toLowerCase() == 'true';
}
