import '../entities/study_progress.dart';
import '../repositories/i_study_progress_repository.dart';

class GetStudyProgress {
  GetStudyProgress(this._studyProgressRepository);

  final IStudyProgressRepository _studyProgressRepository;

  Future<StudyProgress> call() {
    return _studyProgressRepository.getProgress();
  }
}
