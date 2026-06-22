import '../entities/attempt.dart';
import '../repositories/i_attempt_repository.dart';
import '../repositories/i_study_progress_repository.dart';
import '../repositories/i_user_repository.dart';

class SaveAttempt {
  SaveAttempt(
    this._attemptRepository, {
    IUserRepository? userRepository,
    IStudyProgressRepository? studyProgressRepository,
  })  : _userRepository = userRepository,
        _studyProgressRepository = studyProgressRepository;

  final IAttemptRepository _attemptRepository;
  final IUserRepository? _userRepository;
  final IStudyProgressRepository? _studyProgressRepository;

  Future<int> call(Attempt attempt) async {
    final attemptId = await _attemptRepository.saveAttempt(attempt);

    final userRepository = _userRepository;
    if (userRepository != null) {
      if (attempt.isCorrect) {
        await userRepository.recordCorrectAnswer(attempt.userId);
      } else {
        await userRepository.recordWrongAnswer(attempt.userId);
      }
    }

    await _studyProgressRepository?.recordAnsweredQuestion(
      answeredAt: attempt.answeredAt,
    );

    return attemptId;
  }
}
