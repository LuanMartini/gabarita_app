import '../../domain/entities/question.dart';

class EnemQuestionsPage {
  const EnemQuestionsPage({
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
    required this.questions,
  });

  factory EnemQuestionsPage.fromMap(Map<String, dynamic> map) {
    final metadata = map['metadata'];
    final meta =
        metadata is Map<String, dynamic> ? metadata : const <String, dynamic>{};
    final rawQuestions = map['questions'];

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

  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
  final List<EnemQuestionRemoteModel> questions;
}

class EnemQuestionRemoteModel {
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

  factory EnemQuestionRemoteModel.fromMap(Map<String, dynamic> map) {
    final rawAlternatives = map['alternatives'];
    final rawFiles = map['files'];

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
          (map['correctAlternative']?.toString() ?? '').toUpperCase(),
      alternativesIntroduction: map['alternativesIntroduction']?.toString(),
      alternatives: rawAlternatives is List
          ? rawAlternatives
              .whereType<Map<String, dynamic>>()
              .map(EnemAlternativeRemoteModel.fromMap)
              .toList(growable: false)
          : const <EnemAlternativeRemoteModel>[],
    );
  }

  final String title;
  final int index;
  final String? discipline;
  final String? language;
  final int year;
  final String? context;
  final List<String> files;
  final String correctAlternative;
  final String? alternativesIntroduction;
  final List<EnemAlternativeRemoteModel> alternatives;

  bool get canBecomeQuestion {
    return _hasTextualStatement &&
        year > 0 &&
        index > 0 &&
        discipline?.trim().isNotEmpty == true &&
        _hasCompleteAlternatives &&
        !requiresVisualResource;
  }

  bool get requiresVisualResource {
    if (files.any((file) => file.trim().isNotEmpty)) return true;
    if (alternatives.any((alternative) => alternative.hasFile)) return true;

    return _visualReferencePatterns.any(
      (pattern) => pattern.hasMatch(_normalizedText),
    );
  }

  bool get _hasTextualStatement {
    return context?.trim().isNotEmpty == true ||
        alternativesIntroduction?.trim().isNotEmpty == true;
  }

  bool get _hasCompleteAlternatives {
    const expectedLetters = <String>{'A', 'B', 'C', 'D', 'E'};
    final alternativesByLetter = {
      for (final alternative in alternatives) alternative.letter: alternative,
    };

    return alternatives.length == expectedLetters.length &&
        alternativesByLetter.length == expectedLetters.length &&
        alternativesByLetter.keys.toSet().containsAll(expectedLetters) &&
        alternativesByLetter.values.every(
          (alternative) => alternative.text.trim().isNotEmpty,
        ) &&
        expectedLetters.contains(correctAlternative) &&
        alternativesByLetter[correctAlternative]?.isCorrect == true;
  }

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

  String get _normalizedText {
    return _textBlocks
        .join(' ')
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éêë]'), 'e')
        .replaceAll(RegExp(r'[íîï]'), 'i')
        .replaceAll(RegExp(r'[óôõö]'), 'o')
        .replaceAll(RegExp(r'[úûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll('Ã¡', 'a')
        .replaceAll('Ã ', 'a')
        .replaceAll('Ã£', 'a')
        .replaceAll('Ã¢', 'a')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ãª', 'e')
        .replaceAll('Ã­', 'i')
        .replaceAll('Ã³', 'o')
        .replaceAll('Ãµ', 'o')
        .replaceAll('Ã´', 'o')
        .replaceAll('Ãº', 'u')
        .replaceAll('Ã§', 'c');
  }

  Question toQuestion() {
    final byLetter = {
      for (final alternative in alternatives) alternative.letter: alternative,
    };
    final textBlocks = <String>[
      if (context != null && context!.trim().isNotEmpty) context!.trim(),
      if (alternativesIntroduction != null &&
          alternativesIntroduction!.trim().isNotEmpty)
        alternativesIntroduction!.trim(),
    ];

    return Question(
      text: textBlocks.isEmpty ? title : textBlocks.join('\n\n'),
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

  String get _topicLabel {
    if (language == null || language!.isEmpty) return title;
    return '$title - ${language!}';
  }
}

class EnemAlternativeRemoteModel {
  const EnemAlternativeRemoteModel({
    required this.letter,
    required this.text,
    required this.isCorrect,
    this.file,
  });

  factory EnemAlternativeRemoteModel.fromMap(Map<String, dynamic> map) {
    return EnemAlternativeRemoteModel(
      letter: (map['letter']?.toString() ?? '').toUpperCase(),
      text: map['text']?.toString() ?? '',
      file: map['file']?.toString(),
      isCorrect: _asBool(map['isCorrect']),
    );
  }

  final String letter;
  final String text;
  final String? file;
  final bool isCorrect;

  bool get hasFile => file?.trim().isNotEmpty == true;
}

const _visualResource =
    r'(?:figura|figuras|grafico|graficos|tabela|tabelas|mapa|mapas|imagem|imagens|fotografia|fotografias|foto|fotos|quadro|quadros|ilustracao|ilustracoes|esquema|esquemas|diagrama|diagramas|infografico|infograficos|charge|charges)';

final List<RegExp> _visualReferencePatterns = <RegExp>[
  RegExp(
    r'\b(?:observe|analise|veja|considere|conforme|utilize|consultando)\b[\s\S]{0,100}\b' +
        _visualResource +
        r'\b',
  ),
  RegExp(
    r'\b' +
        _visualResource +
        r'\b[\s\S]{0,40}\b(?:abaixo|a seguir|seguinte|apresentad[oa]s?|mostrad[oa]s?|exibid[oa]s?|indicad[oa]s?|representad[oa]s?|ilustrad[oa]s?)\b',
  ),
  RegExp(
    r'\b(?:o|a|os|as)\s+' +
        _visualResource +
        r'\b[\s\S]{0,40}\b(?:mostra|mostram|exibe|exibem|apresenta|apresentam|indica|indicam|representa|representam)\b',
  ),
  RegExp(
    r'\b(?:dados|informacoes|valores)\s+(?:da|na|do|no)\s+' +
        _visualResource +
        r'\b',
  ),
];

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

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _asBool(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value.toString().toLowerCase() == 'true';
}
