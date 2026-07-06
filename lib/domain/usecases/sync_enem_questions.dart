import '../entities/enem_exam.dart';
import '../repositories/i_question_repository.dart';

class SyncEnemQuestions {
  SyncEnemQuestions(this._questionRepository);

  final IQuestionRepository _questionRepository;

  Future<EnemQuestionSyncResult> call({
    required int year,
    int limit = 0,
    String? language,
  }) {
    return _questionRepository.syncEnemQuestions(
      year: year,
      limit: limit,
      language: language,
    );
  }
}
