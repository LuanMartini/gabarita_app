import '../repositories/i_question_repository.dart';

class ToggleFavoriteQuestion {
  ToggleFavoriteQuestion(this._questionRepository);

  final IQuestionRepository _questionRepository;

  Future<int> call({
    required int questionId,
    required bool isFavorite,
  }) {
    return _questionRepository.toggleFavoriteQuestion(
      questionId,
      isFavorite,
    );
  }
}
