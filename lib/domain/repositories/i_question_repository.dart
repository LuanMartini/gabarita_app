import '../entities/question.dart';
import '../entities/enem_exam.dart';

// Bloco 1 - contrato do repositorio de questoes.
// A camada de dominio define o que precisa existir, mas nao define se vem
// de SQLite, JSON, API ou mock. A implementacao real fica na camada data.
abstract class IQuestionRepository {
  // Bloco 2 - garante que o banco offline do ENEM esteja carregado.
  Future<LocalEnemBankSyncResult> ensureLocalEnemBank();

  // Bloco 3 - importa/sincroniza questoes de um ano especifico do JSON local.
  Future<EnemQuestionSyncResult> syncEnemQuestions({
    required int year,
    int limit = 0,
    String? language,
  });

  // Bloco 4 - insere uma questao individual.
  Future<int> insertQuestion(Question question);

  // Bloco 5 - cria questoes mock para teste inicial.
  Future<void> seedMockQuestions({bool force = false});

  // Bloco 6 - busca todas as questoes, nome legado.
  Future<List<Question>> getQuestions();

  // Bloco 7 - busca todas as questoes, nome atual.
  Future<List<Question>> getAllQuestions();

  // Bloco 8 - busca questoes combinando filtros da UI.
  Future<List<Question>> getQuestionsByFilter({
    String? subject,
    String? vestibular,
    List<String>? subjects,
    List<int>? difficulties,
    String? examSource,
    bool favoritesOnly = false,
    String? searchText,
    int? limit,
  });

  // Bloco 9 - seleciona questoes para um simulado.
  Future<List<Question>> getSimuladoQuestions({
    required int quantity,
    List<String>? subjects,
  });

  // Bloco 10 - questoes erradas entram na revisao inteligente.
  Future<List<Question>> getWrongQuestions(int userId);

  // Bloco 11 - questoes favoritas entram na aba de favoritas.
  Future<List<Question>> getFavoriteQuestions();

  // Bloco 12 - liga/desliga favorito.
  Future<int> toggleFavorite(int questionId, bool isFavorite);

  // Bloco 13 - alias de favorito para compatibilidade.
  Future<int> toggleFavoriteQuestion(int questionId, bool isFavorite);

  // Bloco 14 - total de questoes do banco local.
  Future<int> getTotalQuestionsCount();

  // Bloco 15 - questao sugerida do dia.
  Future<Question?> getDailyChallenge(int userId);
}
