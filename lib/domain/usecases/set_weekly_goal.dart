import '../entities/study_progress.dart';
import '../repositories/i_study_progress_repository.dart';

class SetWeeklyGoal {
  SetWeeklyGoal(this._studyProgressRepository);

  final IStudyProgressRepository _studyProgressRepository;

  Future<StudyProgress> call(int value) {
    return _studyProgressRepository.setWeeklyGoalQuestions(value);
  }
}
