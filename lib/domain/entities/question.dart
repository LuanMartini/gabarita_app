// Bloco 1 - entidade pura de dominio.
// A entidade representa uma questao do app sem depender de Flutter, SQLite,
// Provider ou qualquer pacote externo. Isso e importante na Clean Architecture:
// o centro do sistema deve saber apenas as regras do negocio.
class Question {
  // Bloco 2 - construtor principal.
  // Os campos marcados como required sao os minimos para uma questao funcionar:
  // enunciado, disciplina, topico, quatro alternativas e gabarito.
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

  // Bloco 3 - id opcional porque antes de salvar no SQLite a questao ainda nao
  // tem chave primaria. Depois do insert, o banco gera esse numero.
  final int? id;

  // Bloco 4 - enunciado principal da questao.
  final String text;

  // Bloco 5 - disciplina usada nos filtros da tela de questoes e simulados.
  final String subject;

  // Bloco 6 - assunto mais especifico, usado para listar e revisar pontos fracos.
  final String topic;

  // Bloco 7 - dificuldade numerica: 1 facil, 2 medio, 3 dificil.
  final int difficulty;

  // Bloco 8 - ano da prova do ENEM. Pode ser nulo para questoes mockadas.
  final int? year;

  // Bloco 9 - fonte da prova, exemplo "ENEM 2023".
  final String? examSource;

  // Bloco 10 - alternativas salvas separadamente para facilitar SQLite e UI.
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  // Bloco 11 - alternativa E e opcional porque algumas questoes podem ter 4 opcoes.
  final String? optionE;

  // Bloco 12 - gabarito oficial. O app aceita letras como "A", "B", "C" etc.
  final String correctOption;

  // Bloco 13 - texto de feedback/resolucao exibido apos responder.
  final String? explanation;

  // Bloco 14 - mantido por compatibilidade, mas o app prioriza questoes sem imagem.
  final String? imagePath;

  // Bloco 15 - estado de favorito exibido no icone de coracao.
  final bool isFavorite;

  // Bloco 16 - data local de criacao/importacao da questao.
  final DateTime createdAt;

  // Bloco 17 - apelido usado por telas antigas que esperavam "bank".
  String get bank => examSource ?? 'Banco local';

  // Bloco 18 - apelido usado por telas antigas que esperavam "discipline".
  String get discipline => subject;

  // Bloco 19 - apelido usado por telas antigas que esperavam "examYear".
  int? get examYear => year;

  // Bloco 20 - apelido usado por telas antigas que esperavam "statement".
  String get statement => text;

  // Bloco 21 - lista de alternativas na ordem visual.
  // O values vem do mapa options, portanto mantem A, B, C, D e E nessa ordem.
  List<String> get alternatives => options.values.toList(growable: false);

  // Bloco 22 - converte a letra correta para indice.
  // Exemplo: A vira 0, B vira 1, C vira 2. Isso ajuda widgets que trabalham
  // com indices em vez de letras.
  int get correctAlternativeIndex {
    const letters = <String>['A', 'B', 'C', 'D', 'E'];
    final index = letters.indexOf(normalizedCorrectOption);
    return index < 0 ? 0 : index;
  }

  // Bloco 23 - gabarito sempre em maiusculo e sem espacos.
  String get normalizedCorrectOption => normalizeOption(correctOption);

  // Bloco 24 - funcao utilitaria para padronizar qualquer alternativa.
  // Ela evita erro quando uma resposta chega como " c " e o gabarito e "C".
  static String normalizeOption(String option) => option.trim().toUpperCase();

  // Bloco 25 - texto mostrado no feedback.
  String get feedback => explanation ?? 'Sem explicacao cadastrada.';

  // Bloco 26 - regra principal de correcao.
  // Repare que a entidade consegue decidir se a resposta esta certa sem saber
  // quem clicou no botao, qual tela chamou ou onde a questao foi salva.
  bool isCorrectAnswer(String selectedOption) {
    return normalizeOption(selectedOption) == normalizedCorrectOption;
  }

  // Bloco 27 - mapa letra -> texto da alternativa.
  // A alternativa E so aparece se existir conteudo.
  Map<String, String> get options {
    return {
      'A': optionA,
      'B': optionB,
      'C': optionC,
      'D': optionD,
      if (optionE != null && optionE!.isNotEmpty) 'E': optionE!,
    };
  }

  // Bloco 28 - cria uma copia alterando apenas os campos informados.
  // Isso evita modificar o objeto original e facilita Provider/Repository.
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
