import '../../domain/entities/study_session.dart';
import '../../domain/repositories/i_study_session_repository.dart';
import '../datasources/local/database_helper.dart';

class StudySessionRepositoryImpl implements IStudySessionRepository {
  StudySessionRepositoryImpl([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  @override
  Future<void> saveStudySession(StudySession session) {
    return _dbHelper.insertStudySession(session);
  }

  @override
  Future<List<StudySession>> getStudySessionsByUser(
    int userId, {
    int? limit,
  }) {
    return _dbHelper.getStudySessionsByUser(userId, limit: limit);
  }

  @override
  Future<List<StudySession>> getRecentSimulados(
    int userId, {
    int limit = 5,
  }) async {
    final sessions = await _dbHelper.getStudySessionsByUser(
      userId,
    );
    return sessions
        .where((session) => session.type == StudySessionType.simulado)
        .take(limit)
        .toList();
  }
}
