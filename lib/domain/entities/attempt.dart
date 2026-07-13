// Bloco 1 - entidade de tentativa/resposta.
// Cada vez que o aluno confirma uma alternativa, uma Attempt pode ser salva.
class Attempt {
  // Bloco 2 - construtor com os dados minimos de uma resposta.
  Attempt({
    this.id,
    required this.userId,
    required this.questionId,
    required this.sessionId,
    required this.selectedOption,
    required this.isCorrect,
    this.timeTakenSeconds = 0,
    this.latitude,
    this.longitude,
    this.locationName,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  // Bloco 3 - id opcional ate o SQLite gerar a chave.
  final int? id;

  // Bloco 4 - usuario que respondeu.
  final int userId;

  // Bloco 5 - questao respondida.
  final int questionId;

  // Bloco 6 - sessao/simulado em que a resposta aconteceu.
  final String sessionId;

  // Bloco 7 - alternativa marcada pelo aluno.
  final String selectedOption;

  // Bloco 8 - resultado ja calculado no momento da resposta.
  final bool isCorrect;

  // Bloco 9 - tempo gasto na questao, em segundos.
  final int timeTakenSeconds;

  // Bloco 10 - latitude opcional do local de estudo.
  final double? latitude;

  // Bloco 11 - longitude opcional do local de estudo.
  final double? longitude;

  // Bloco 12 - nome amigavel do local, se existir.
  final String? locationName;

  // Bloco 13 - data/hora em que respondeu.
  final DateTime answeredAt;

  // Bloco 14 - cria copia alterando apenas campos informados.
  Attempt copyWith({
    int? id,
    int? userId,
    int? questionId,
    String? sessionId,
    String? selectedOption,
    bool? isCorrect,
    int? timeTakenSeconds,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? answeredAt,
  }) {
    return Attempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      sessionId: sessionId ?? this.sessionId,
      selectedOption: selectedOption ?? this.selectedOption,
      isCorrect: isCorrect ?? this.isCorrect,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}
