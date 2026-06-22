import '../entities/user.dart';
import '../repositories/i_attempt_repository.dart';
import '../repositories/i_user_repository.dart';

class UserStatistics {
  const UserStatistics({
    required this.user,
    required this.totalAnswered,
    required this.totalCorrect,
    required this.accuracyRate,
    required this.currentStreak,
    required this.maxStreak,
    required this.accuracyBySubject,
    required this.weeklyProgress,
    required this.topStudyLocations,
  });

  final User user;
  final int totalAnswered;
  final int totalCorrect;
  final double accuracyRate;
  final int currentStreak;
  final int maxStreak;
  final Map<String, double> accuracyBySubject;
  final List<Map<String, dynamic>> weeklyProgress;
  final List<Map<String, dynamic>> topStudyLocations;
}

class GetUserStatistics {
  GetUserStatistics(
    this._userRepository,
    this._attemptRepository,
  );

  final IUserRepository _userRepository;
  final IAttemptRepository _attemptRepository;

  Future<UserStatistics?> call(int userId) async {
    final user = await _userRepository.getUser(userId);
    if (user == null) return null;

    final accuracyBySubject =
        await _attemptRepository.getAccuracyBySubject(userId);
    final weeklyProgress = await _attemptRepository.getWeeklyProgress(userId);
    final topStudyLocations =
        await _attemptRepository.getTopStudyLocations(userId);

    return UserStatistics(
      user: user,
      totalAnswered: user.totalAnswered,
      totalCorrect: user.totalCorrect,
      accuracyRate: user.accuracyRate,
      currentStreak: user.currentStreak,
      maxStreak: user.maxStreak,
      accuracyBySubject: accuracyBySubject,
      weeklyProgress: weeklyProgress,
      topStudyLocations: topStudyLocations,
    );
  }
}
