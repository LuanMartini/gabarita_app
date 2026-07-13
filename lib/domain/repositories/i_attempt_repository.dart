import '../entities/attempt.dart';

// Bloco 1 - contrato das tentativas/respostas.
// O dominio define quais operacoes existem; a camada data decide como salvar.
abstract class IAttemptRepository {
  // Bloco 2 - salva uma resposta e atualiza estatisticas relacionadas.
  Future<int> saveAttempt(Attempt attempt);

  // Bloco 3 - historico de respostas de um usuario.
  Future<List<Attempt>> getAttemptsByUser(int userId, {int? limit});

  // Bloco 4 - respostas de uma sessao/simulado especifico.
  Future<List<Attempt>> getAttemptsBySession(String sessionId);

  // Bloco 5 - acerto por disciplina para alimentar barras de progresso.
  Future<Map<String, double>> getAccuracyBySubject(int userId);

  // Bloco 6 - progresso semanal para graficos e gamificacao.
  Future<List<Map<String, dynamic>>> getWeeklyProgress(int userId);

  // Bloco 7 - locais mais frequentes de estudo usando dados de GPS.
  Future<List<Map<String, dynamic>>> getTopStudyLocations(
    int userId, {
    int limit = 5,
  });
}
