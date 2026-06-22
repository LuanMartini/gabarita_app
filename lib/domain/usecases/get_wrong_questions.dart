import '../entities/question.dart';
import '../repositories/i_question_repository.dart';

class GetWrongQuestions {
  GetWrongQuestions(this._questionRepository);

  final IQuestionRepository _questionRepository;

  Future<List<Question>> call(int userId) {
    return _questionRepository.getWrongQuestions(userId);
  }
}
