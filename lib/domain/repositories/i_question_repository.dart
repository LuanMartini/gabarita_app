import '../entities/question.dart';
import '../entities/enem_exam.dart';

abstract class IQuestionRepository {
  Future<List<EnemExam>> getAvailableEnemExams();
  Future<EnemQuestionSyncResult> syncEnemQuestions({
    required int year,
    int limit = 0,
    String? language,
  });
  Future<int> insertQuestion(Question question);
  Future<void> seedMockQuestions({bool force = false});
  Future<List<Question>> getQuestions();
  Future<List<Question>> getAllQuestions();
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
  Future<List<Question>> getWrongQuestions(int userId);
  Future<List<Question>> getFavoriteQuestions();
  Future<int> toggleFavorite(int questionId, bool isFavorite);
  Future<int> toggleFavoriteQuestion(int questionId, bool isFavorite);
  Future<int> getTotalQuestionsCount();
  Future<Question?> getDailyChallenge(int userId);
}
