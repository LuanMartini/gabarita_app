import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/repositories/attempt_repository_impl.dart';
import 'package:gabarita_app/data/repositories/question_repository_impl.dart';
import 'package:gabarita_app/domain/entities/question.dart';
import 'package:gabarita_app/domain/usecases/ensure_local_enem_bank.dart';
import 'package:gabarita_app/domain/usecases/get_questions_by_filter.dart';
import 'package:gabarita_app/domain/usecases/get_wrong_questions.dart';
import 'package:gabarita_app/domain/usecases/save_attempt.dart';
import 'package:gabarita_app/domain/usecases/toggle_favorite_question.dart';
import 'package:gabarita_app/presentation/providers/questions_provider.dart';

void main() {
  final question = Question(
    text: 'Enunciado',
    subject: 'Matematica',
    topic: 'Topico',
    optionA: 'A',
    optionB: 'B',
    optionC: 'C',
    optionD: 'D',
    correctOption: ' b ',
  );

  test('normaliza a alternativa antes de corrigir a resposta', () {
    expect(question.isCorrectAnswer(' B '), isTrue);
    expect(question.isCorrectAnswer('a'), isFalse);
    expect(question.normalizedCorrectOption, 'B');
    expect(question.correctAlternativeIndex, 1);
  });

  test('feedback recalcula o acerto pela questao exibida', () {
    final questionRepository = QuestionRepositoryImpl();
    final attemptRepository = AttemptRepositoryImpl();
    final provider = QuestionsProvider(
      ensureLocalEnemBank: EnsureLocalEnemBank(questionRepository),
      getQuestionsByFilter: GetQuestionsByFilter(questionRepository),
      getWrongQuestions: GetWrongQuestions(questionRepository),
      toggleFavoriteQuestion: ToggleFavoriteQuestion(questionRepository),
      saveAttempt: SaveAttempt(attemptRepository),
    );

    final feedback = provider.registerAnsweredFeedback(
      question: question.copyWith(id: 1, correctOption: 'C'),
      selectedOption: 'c',
      isCorrect: false,
    );

    expect(feedback?.selectedOption, 'C');
    expect(feedback?.correctOption, 'C');
    expect(feedback?.isCorrect, isTrue);
    expect(feedback?.xpEarned, 15);
  });
}
