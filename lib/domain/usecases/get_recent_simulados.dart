import '../entities/study_session.dart';
import '../repositories/i_study_session_repository.dart';

class GetRecentSimulados {
  GetRecentSimulados(this._studySessionRepository);

  final IStudySessionRepository _studySessionRepository;

  Future<List<StudySession>> call(
    int userId, {
    int limit = 5,
  }) {
    return _studySessionRepository.getRecentSimulados(userId, limit: limit);
  }
}
