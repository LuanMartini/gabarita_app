import '../entities/question.dart';
import '../repositories/i_question_repository.dart';

// Bloco 1 - caso de uso para buscar questoes que o usuario errou.
// Essas questoes alimentam a tela de Revisao Inteligente.
class GetWrongQuestions {
  // Bloco 2 - injeta a interface do repositorio de questoes.
  GetWrongQuestions(this._questionRepository);

  final IQuestionRepository _questionRepository;

  // Bloco 3 - recebe o id do usuario e devolve as questoes erradas dele.
  Future<List<Question>> call(int userId) {
    return _questionRepository.getWrongQuestions(userId);
  }
}
