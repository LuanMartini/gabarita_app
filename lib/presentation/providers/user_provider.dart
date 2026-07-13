import 'package:flutter/foundation.dart';

import '../../domain/entities/study_progress.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_or_create_user.dart';
import '../../domain/usecases/get_study_progress.dart';
import '../../domain/usecases/get_user_statistics.dart';
import '../../domain/usecases/set_weekly_goal.dart';
import '../../domain/usecases/update_user_avatar.dart';
import '../../domain/usecases/update_user_name.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({
    required GetOrCreateUser getOrCreateUser,
    required GetUserStatistics getUserStatistics,
    required GetStudyProgress getStudyProgress,
    required SetWeeklyGoal setWeeklyGoal,
    required UpdateUserAvatar updateUserAvatar,
    required UpdateUserName updateUserName,
  })  : _getOrCreateUser = getOrCreateUser,
        _getUserStatistics = getUserStatistics,
        _getStudyProgress = getStudyProgress,
        _setWeeklyGoal = setWeeklyGoal,
        _updateUserAvatar = updateUserAvatar,
        _updateUserName = updateUserName;

  final GetOrCreateUser _getOrCreateUser;
  final GetUserStatistics _getUserStatistics;
  final GetStudyProgress _getStudyProgress;
  final SetWeeklyGoal _setWeeklyGoal;
  final UpdateUserAvatar _updateUserAvatar;
  final UpdateUserName _updateUserName;

  User? _user;
  UserStatistics? _statistics;
  StudyProgress? _progress;
  bool _isLoading = false;
  int _avatarVersion = 0;
  String? _errorMessage;

  User? get user => _user;
  UserStatistics? get statistics => _statistics;
  StudyProgress? get progress => _progress;
  bool get isLoading => _isLoading;
  int get avatarVersion => _avatarVersion;
  String? get errorMessage => _errorMessage;

  int get userId => _user?.id ?? 1;
  double get accuracyRate => _statistics?.accuracyRate ?? 0;
  int get totalAnswered => _statistics?.totalAnswered ?? 0;
  int get totalCorrect => _statistics?.totalCorrect ?? 0;
  int get currentStreak => _progress?.currentStreak ?? 0;
  int get maxStreak => _progress?.maxStreak ?? 0;
  int get weeklyGoalQuestions => _progress?.weeklyGoalQuestions ?? 50;
  int get weeklyAnsweredQuestions => _progress?.weeklyAnsweredQuestions ?? 0;
  int get remainingWeeklyQuestions =>
      _progress?.remainingWeeklyQuestions ?? weeklyGoalQuestions;
  double get weeklyGoalProgress => _progress?.weeklyProgressRate ?? 0;

  Future<void> loadUser({int? userId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final previousAvatar = _user?.avatar;
      final preferredUserId = userId ?? _user?.id;
      _user = await _getOrCreateUser(userId: preferredUserId);
      if (previousAvatar != _user?.avatar) {
        _avatarVersion++;
      }
      final resolvedUserId = userId ?? _user?.id;
      if (resolvedUserId != null) {
        _statistics = await _getUserStatistics(resolvedUserId);
      }
      _progress = await _getStudyProgress();
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar o perfil.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh({int? userId}) {
    return loadUser(userId: userId);
  }

  Future<void> updateWeeklyGoal(int value) async {
    try {
      _progress = await _setWeeklyGoal(value);
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Nao foi possivel atualizar a meta semanal.';
      notifyListeners();
    }
  }

  Future<void> updateName(String name) async {
    final user = _user;
    if (user?.id == null) {
      throw StateError('Perfil local nao encontrado.');
    }

    final updatedName = await _updateUserName(userId: user!.id!, name: name);
    _user = user.copyWith(name: updatedName);
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateAvatar(String avatarPath) async {
    final user = _user;
    if (user?.id == null) {
      throw StateError('Perfil local nao encontrado.');
    }

    final updatedUser = await _updateUserAvatar(
      userId: user!.id!,
      avatarPath: avatarPath,
    );
    _user = updatedUser;
    _avatarVersion++;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> clearAvatar() async {
    final user = _user;
    if (user?.id == null) {
      throw StateError('Perfil local nao encontrado.');
    }

    _user = await _updateUserAvatar(userId: user!.id!, avatarPath: null);
    _avatarVersion++;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
