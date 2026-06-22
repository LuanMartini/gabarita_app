import '../entities/study_session.dart';

abstract class IStudySessionRepository {
  Future<void> saveStudySession(StudySession session);

  Future<List<StudySession>> getStudySessionsByUser(
    int userId, {
    int? limit,
  });

  Future<List<StudySession>> getRecentSimulados(
    int userId, {
    int limit = 5,
  });
}
