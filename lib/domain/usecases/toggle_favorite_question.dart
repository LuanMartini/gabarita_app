import '../repositories/i_question_repository.dart';

// Bloco 1 - caso de uso para favoritar/desfavoritar uma questao.
// Ele existe para a tela nao chamar o banco diretamente.
class ToggleFavoriteQuestion {
  // Bloco 2 - injeta o contrato do repositorio de questoes.
  ToggleFavoriteQuestion(this._questionRepository);

  final IQuestionRepository _questionRepository;

  // Bloco 3 - altera o favorito de uma questao especifica.
  Future<int> call({
    required int questionId,
    required bool isFavorite,
  }) {
    // Bloco 4 - delega ao repositorio. O Provider decide o estado visual,
    // e o repositorio persiste no SQLite.
    return _questionRepository.toggleFavoriteQuestion(
      questionId,
      isFavorite,
    );
  }
}
