import '../entities/enem_exam.dart';
import '../repositories/i_question_repository.dart';

class EnsureLocalEnemBank {
  EnsureLocalEnemBank(this._questionRepository);

  final IQuestionRepository _questionRepository;

  Future<LocalEnemBankSyncResult> call() {
    return _questionRepository.ensureLocalEnemBank();
  }
}
