import '../entities/user.dart';
import '../repositories/i_attempt_repository.dart';
import '../repositories/i_user_repository.dart';

// Bloco 1 - objeto de resposta do caso de uso de estatisticas.
// Ele junta dados do usuario e dados calculados a partir das tentativas.
class UserStatistics {
  // Bloco 2 - construtor com todos os dados que a tela de estatisticas precisa.
  const UserStatistics({
    required this.user,
    required this.totalAnswered,
    required this.totalCorrect,
    required this.accuracyRate,
    required this.currentStreak,
    required this.maxStreak,
    required this.accuracyBySubject,
    required this.weeklyProgress,
    required this.topStudyLocations,
  });

  // Bloco 3 - perfil completo do usuario.
  final User user;

  // Bloco 4 - total de questoes respondidas.
  final int totalAnswered;

  // Bloco 5 - total de acertos.
  final int totalCorrect;

  // Bloco 6 - taxa geral de acerto entre 0.0 e 1.0.
  final double accuracyRate;

  // Bloco 7 - ofensiva atual.
  final int currentStreak;

  // Bloco 8 - maior ofensiva historica.
  final int maxStreak;

  // Bloco 9 - porcentagem de acerto por disciplina.
  final Map<String, double> accuracyBySubject;

  // Bloco 10 - progresso semanal usado em graficos/listas.
  final List<Map<String, dynamic>> weeklyProgress;

  // Bloco 11 - locais onde o aluno mais estudou, quando GPS estiver disponivel.
  final List<Map<String, dynamic>> topStudyLocations;
}

// Bloco 12 - caso de uso que monta o painel estatistico do usuario.
class GetUserStatistics {
  // Bloco 13 - precisa do repositorio de usuario e do repositorio de tentativas.
  GetUserStatistics(
    this._userRepository,
    this._attemptRepository,
  );

  final IUserRepository _userRepository;
  final IAttemptRepository _attemptRepository;

  // Bloco 14 - calcula/carrega tudo para um usuario.
  Future<UserStatistics?> call(int userId) async {
    // Bloco 15 - se o perfil nao existe, nao ha estatisticas para exibir.
    final user = await _userRepository.getUser(userId);
    if (user == null) return null;

    // Bloco 16 - estatisticas que dependem do historico de tentativas.
    final accuracyBySubject =
        await _attemptRepository.getAccuracyBySubject(userId);
    final weeklyProgress = await _attemptRepository.getWeeklyProgress(userId);
    final topStudyLocations =
        await _attemptRepository.getTopStudyLocations(userId);

    // Bloco 17 - junta os totais do usuario com os calculos do repositorio.
    return UserStatistics(
      user: user,
      totalAnswered: user.totalAnswered,
      totalCorrect: user.totalCorrect,
      accuracyRate: user.accuracyRate,
      currentStreak: user.currentStreak,
      maxStreak: user.maxStreak,
      accuracyBySubject: accuracyBySubject,
      weeklyProgress: weeklyProgress,
      topStudyLocations: topStudyLocations,
    );
  }
}
