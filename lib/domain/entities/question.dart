class Question {
  Question({
    this.id,
    required this.text,
    required this.subject,
    required this.topic,
    this.difficulty = 2,
    this.year,
    this.examSource,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.optionE,
    required this.correctOption,
    this.explanation,
    this.imagePath,
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String text;
  final String subject;
  final String topic;
  final int difficulty;
  final int? year;
  final String? examSource;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String? optionE;
  final String correctOption;
  final String? explanation;
  final String? imagePath;
  final bool isFavorite;
  final DateTime createdAt;

  String get bank => examSource ?? 'Banco local';

  String get discipline => subject;

  int? get examYear => year;

  String get statement => text;

  List<String> get alternatives => options.values.toList(growable: false);

  int get correctAlternativeIndex {
    const letters = <String>['A', 'B', 'C', 'D', 'E'];
    final index = letters.indexOf(correctOption.toUpperCase());
    return index < 0 ? 0 : index;
  }

  String get feedback => explanation ?? 'Sem explicacao cadastrada.';

  bool isCorrectAnswer(String selectedOption) {
    return selectedOption.toUpperCase() == correctOption.toUpperCase();
  }

  Map<String, String> get options {
    return {
      'A': optionA,
      'B': optionB,
      'C': optionC,
      'D': optionD,
      if (optionE != null && optionE!.isNotEmpty) 'E': optionE!,
    };
  }

  Question copyWith({
    int? id,
    String? text,
    String? subject,
    String? topic,
    int? difficulty,
    int? year,
    String? examSource,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? optionE,
    String? correctOption,
    String? explanation,
    String? imagePath,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      year: year ?? this.year,
      examSource: examSource ?? this.examSource,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      optionE: optionE ?? this.optionE,
      correctOption: correctOption ?? this.correctOption,
      explanation: explanation ?? this.explanation,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
