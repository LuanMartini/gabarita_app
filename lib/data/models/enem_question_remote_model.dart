import '../../domain/entities/question.dart';
import '../../domain/services/question_quality_policy.dart';

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
    final rawQuestions = map['questions'];
    final meta =
        metadata is Map<String, dynamic> ? metadata : const <String, dynamic>{};

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
    return QuestionQualityPolicy.hasVisualDependency(
      textBlocks: _textBlocks,
      files: <String?>[
        ...files,
        ...alternatives.map((alternative) => alternative.file),
      ],
    );
  }

  Question toQuestion() {
    final byLetter = <String, EnemAlternativeRemoteModel>{
      for (final alternative in alternatives) alternative.letter: alternative,
    };
    final statementBlocks = <String>[
      if (context != null && context!.trim().isNotEmpty) context!.trim(),
      if (alternativesIntroduction != null &&
          alternativesIntroduction!.trim().isNotEmpty)
        alternativesIntroduction!.trim(),
    ];

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

  bool get _hasTextualStatement {
    return context?.trim().isNotEmpty == true ||
        alternativesIntroduction?.trim().isNotEmpty == true;
  }

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
      letter: (map['letter']?.toString() ?? '').trim().toUpperCase(),
      text: map['text']?.toString() ?? '',
      file: map['file']?.toString(),
      isCorrect: _asBool(map['isCorrect']),
    );
  }

  final String letter;
  final String text;
  final String? file;
  final bool isCorrect;
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
