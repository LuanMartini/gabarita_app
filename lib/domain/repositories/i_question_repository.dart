import '../entities/question.dart';

abstract class IQuestionRepository {
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
