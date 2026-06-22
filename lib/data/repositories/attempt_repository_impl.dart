import '../../domain/entities/attempt.dart';
import '../../domain/repositories/i_attempt_repository.dart';
import '../datasources/local/database_helper.dart';

class AttemptRepositoryImpl implements IAttemptRepository {
  AttemptRepositoryImpl([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  @override
  Future<int> saveAttempt(Attempt attempt) {
    return _dbHelper.insertAttempt(attempt);
  }

  @override
  Future<List<Attempt>> getAttemptsByUser(int userId, {int? limit}) {
    return _dbHelper.getAttemptsByUser(userId, limit: limit);
  }

  @override
  Future<List<Attempt>> getAttemptsBySession(String sessionId) {
    return _dbHelper.getAttemptsBySession(sessionId);
  }

  @override
  Future<Map<String, double>> getAccuracyBySubject(int userId) {
    return _dbHelper.getAccuracyBySubject(userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyProgress(int userId) {
    return _dbHelper.getWeeklyProgress(userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getTopStudyLocations(
    int userId, {
    int limit = 5,
  }) {
    return _dbHelper.getTopStudyLocations(userId, limit: limit);
  }
}
