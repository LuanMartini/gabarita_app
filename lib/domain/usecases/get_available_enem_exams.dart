import '../entities/enem_exam.dart';
import '../repositories/i_question_repository.dart';

class GetAvailableEnemExams {
  GetAvailableEnemExams(this._questionRepository);

  final IQuestionRepository _questionRepository;

  Future<List<EnemExam>> call() {
    return _questionRepository.getAvailableEnemExams();
  }
}
