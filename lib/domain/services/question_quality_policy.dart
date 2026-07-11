import '../entities/question.dart';

class QuestionQualityPolicy {
  const QuestionQualityPolicy._();

  static bool isUsable(
    Question question, {
    bool requireFiveAlternatives = false,
  }) {
    final correctOption = question.correctOption.trim().toUpperCase();
    final options = question.options.map(
      (key, value) => MapEntry(key.trim().toUpperCase(), value.trim()),
    );

    final requiredOptions = requireFiveAlternatives
        ? const <String>['A', 'B', 'C', 'D', 'E']
        : const <String>['A', 'B', 'C', 'D'];

    return question.text.trim().isNotEmpty &&
        question.subject.trim().isNotEmpty &&
        question.topic.trim().isNotEmpty &&
        requiredOptions.every(
          (option) => options[option]?.isNotEmpty == true,
        ) &&
        options.containsKey(correctOption) &&
        !hasVisualDependency(
          textBlocks: <String>[
            question.text,
            question.topic,
            ...options.values,
          ],
          files: <String?>[question.imagePath],
        );
  }

  static bool hasVisualDependency({
    Iterable<String> textBlocks = const <String>[],
    Iterable<String?> files = const <String?>[],
  }) {
    if (files.any((file) => file?.trim().isNotEmpty == true)) return true;

    final text = normalizeText(textBlocks.join(' '));
    if (text.trim().isEmpty) return false;

    if (_embeddedImagePattern.hasMatch(text)) return true;
    return _visualReferencePatterns.any((pattern) => pattern.hasMatch(text));
  }

  static String contentKey(Question question) {
    return normalizeForComparison(
      <String>[
        question.text,
        question.optionA,
        question.optionB,
        question.optionC,
        question.optionD,
        question.optionE ?? '',
        question.correctOption,
      ].join('|'),
    );
  }

  static String normalizeForComparison(String value) {
    return normalizeText(value).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String normalizeText(String value) {
    var normalized = value.toLowerCase();

    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'Ã¡': 'a',
      'Ã ': 'a',
      'Ã£': 'a',
      'Ã¢': 'a',
      'Ã¤': 'a',
      'Ã©': 'e',
      'Ãª': 'e',
      'Ã«': 'e',
      'Ã­': 'i',
      'Ã®': 'i',
      'Ã¯': 'i',
      'Ã³': 'o',
      'Ã´': 'o',
      'Ãµ': 'o',
      'Ã¶': 'o',
      'Ãº': 'u',
      'Ã»': 'u',
      'Ã¼': 'u',
      'Ã§': 'c',
    };

    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key.toLowerCase(), entry.value);
    }
    return normalized;
  }

  static final RegExp _embeddedImagePattern = RegExp(
    r'!\[|raw\.githubusercontent|/questions/|\.(?:png|jpe?g|gif|webp|svg)\b',
  );

  static const String _visualResource =
      r'(?:figura|figuras|grafico|graficos|tabela|tabelas|mapa|mapas|imagem|imagens|fotografia|fotografias|foto|fotos|quadro|quadros|cartaz|cartazes|tirinha|tirinhas|charge|charges|ilustracao|ilustracoes|esquema|esquemas|diagrama|diagramas|infografico|infograficos)';

  static final List<RegExp> _visualReferencePatterns = <RegExp>[
    RegExp(
      r'\b(?:observe|analise|veja|considere|conforme|utilize|consultando|com base)\b[\s\S]{0,120}\b' +
          _visualResource +
          r'\b',
    ),
    RegExp(
      r'\b' +
          _visualResource +
          r'\b[\s\S]{0,80}\b(?:abaixo|acima|a seguir|seguinte|apresentad[oa]s?|mostrad[oa]s?|exibid[oa]s?|indicad[oa]s?|representad[oa]s?|ilustrad[oa]s?)\b',
    ),
    RegExp(
      r'\b(?:o|a|os|as)\s+' +
          _visualResource +
          r'\b[\s\S]{0,80}\b(?:mostra|mostram|exibe|exibem|apresenta|apresentam|indica|indicam|representa|representam)\b',
    ),
    RegExp(
      r'\b(?:dados|informacoes|valores)\s+(?:da|na|do|no)\s+' +
          _visualResource +
          r'\b',
    ),
  ];
}
