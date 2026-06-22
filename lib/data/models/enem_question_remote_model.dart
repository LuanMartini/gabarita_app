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
    return title.isNotEmpty &&
        year > 0 &&
        index > 0 &&
        correctAlternative.length == 1 &&
        alternatives.length >= 4;
  }

  Question toQuestion() {
    final byLetter = {
      for (final alternative in alternatives) alternative.letter: alternative,
    };
    final intro = alternativesIntroduction;
    final imageBlocks = files.indexed.map((entry) {
      final imageNumber = entry.$1 + 1;
      return '![Imagem $imageNumber da questao](${entry.$2})';
    });
    final textBlocks = <String>[
      if (context != null && context!.trim().isNotEmpty) context!.trim(),
      if (intro != null && intro.trim().isNotEmpty) intro.trim(),
      ...imageBlocks,
    ];

    return Question(
      text: textBlocks.isEmpty ? title : textBlocks.join('\n\n'),
      subject: _disciplineLabel(discipline),
      topic: _topicLabel,
      difficulty: 2,
      year: year,
      examSource: 'ENEM $year',
      optionA: byLetter['A']?._markdownText ?? '',
      optionB: byLetter['B']?._markdownText ?? '',
      optionC: byLetter['C']?._markdownText ?? '',
      optionD: byLetter['D']?._markdownText ?? '',
      optionE: byLetter['E']?._markdownText,
      correctOption: correctAlternative,
      explanation: 'Gabarito oficial: alternativa $correctAlternative.',
      imagePath: files.isNotEmpty ? files.first : null,
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

  String get _markdownText {
    final blocks = <String>[
      if (text.trim().isNotEmpty) text.trim(),
      if (file != null && file!.trim().isNotEmpty)
        '![Alternativa $letter](${file!.trim()})',
    ];
    return blocks.join('\n\n');
  }
}

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
