// Bloco 1 - entidade pura do usuario.
// Aqui ficam apenas os dados e regras simples do aluno logado localmente.
// Nao existe codigo de tela, Provider, SQLite ou camera nesta classe.
class User {
  // Bloco 2 - construtor do perfil.
  // O app trabalha offline e com um perfil principal, entao varios campos
  // recebem valores padrao para o usuario conseguir abrir o app sem cadastro.
  User({
    this.id,
    required this.name,
    this.avatar,
    DateTime? createdAt,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.totalAnswered = 0,
    this.totalCorrect = 0,
    this.studyGoalMinutes = 30,
    this.notificationsEnabled = true,
    this.notificationHour = 19,
    this.notificationMinute = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  // Bloco 3 - id opcional ate o perfil ser salvo no banco.
  final int? id;

  // Bloco 4 - nome exibido na Home e no Perfil.
  final String name;

  // Bloco 5 - foto do perfil.
  // Neste projeto pode ser null ou um data URI base64 da imagem escolhida.
  final String? avatar;

  // Bloco 6 - data em que o perfil foi criado localmente.
  final DateTime createdAt;

  // Bloco 7 - ofensiva atual em dias consecutivos de estudo.
  final int currentStreak;

  // Bloco 8 - maior ofensiva ja alcancada.
  final int maxStreak;

  // Bloco 9 - total de questoes respondidas pelo usuario.
  final int totalAnswered;

  // Bloco 10 - total de respostas corretas.
  final int totalCorrect;

  // Bloco 11 - meta diaria/semanal de estudo em minutos.
  final int studyGoalMinutes;

  // Bloco 12 - controle simples para lembretes de estudo.
  final bool notificationsEnabled;

  // Bloco 13 - hora padrao do lembrete.
  final int notificationHour;

  // Bloco 14 - minuto padrao do lembrete.
  final int notificationMinute;

  // Bloco 15 - taxa de acerto calculada a partir dos totais.
  // Se ainda nao respondeu nada, retorna 0 para evitar divisao por zero.
  double get accuracyRate {
    if (totalAnswered == 0) return 0;
    return totalCorrect / totalAnswered;
  }

  // Bloco 16 - cria uma copia alterando apenas o que mudou.
  // Isso e usado quando o Provider muda nome, foto, stats ou preferencias.
  User copyWith({
    int? id,
    String? name,
    String? avatar,
    DateTime? createdAt,
    int? currentStreak,
    int? maxStreak,
    int? totalAnswered,
    int? totalCorrect,
    int? studyGoalMinutes,
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      studyGoalMinutes: studyGoalMinutes ?? this.studyGoalMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
    );
  }
}
