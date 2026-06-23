import '../entities/question.dart';
import '../repositories/i_question_repository.dart';

class AddQuestion {
  AddQuestion(this._repository);

  final IQuestionRepository _repository;

  Future<int> call(Question question) {
    return _repository.insertQuestion(question);
  }
}
