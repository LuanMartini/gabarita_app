import '../entities/question.dart';
import '../repositories/i_question_repository.dart';

// Bloco 1 - caso de uso que gera uma lista de questoes para simulado.
// A tela escolhe quantidade e materias; o dominio pede ao repositorio a lista.
class GenerateSimulado {
  // Bloco 2 - injeta o contrato de questoes.
  GenerateSimulado(this._questionRepository);

  final IQuestionRepository _questionRepository;

  // Bloco 3 - quantity vem do Slider; subjects vem dos ChoiceChips.
  Future<List<Question>> call({
    required int quantity,
    List<String> subjects = const <String>[],
  }) {
    // Bloco 4 - lista vazia de materias significa "todas as materias".
    return _questionRepository.getSimuladoQuestions(
      quantity: quantity,
      subjects: subjects.isEmpty ? null : subjects,
    );
  }
}
