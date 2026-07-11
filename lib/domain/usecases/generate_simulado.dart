import '../entities/question.dart';
import '../repositories/i_question_repository.dart';

class GenerateSimulado {
  GenerateSimulado(this._questionRepository);

  final IQuestionRepository _questionRepository;

  Future<List<Question>> call({
    required int quantity,
    List<String> subjects = const <String>[],
  }) {
    return _questionRepository.getSimuladoQuestions(
      quantity: quantity,
      subjects: subjects.isEmpty ? null : subjects,
    );
  }
}
