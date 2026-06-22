import '../entities/attempt.dart';

abstract class IAttemptRepository {
  Future<int> saveAttempt(Attempt attempt);
  Future<List<Attempt>> getAttemptsByUser(int userId, {int? limit});
  Future<List<Attempt>> getAttemptsBySession(String sessionId);
  Future<Map<String, double>> getAccuracyBySubject(int userId);
  Future<List<Map<String, dynamic>>> getWeeklyProgress(int userId);
  Future<List<Map<String, dynamic>>> getTopStudyLocations(
    int userId, {
    int limit = 5,
  });
}
