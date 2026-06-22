import '../entities/study_session.dart';
import '../repositories/i_study_session_repository.dart';

class SaveStudySession {
  SaveStudySession(this._studySessionRepository);

  final IStudySessionRepository _studySessionRepository;

  Future<void> call(StudySession session) {
    return _studySessionRepository.saveStudySession(session);
  }
}
