import 'package:flutter/foundation.dart';

import '../../domain/entities/study_progress.dart';
import '../../domain/usecases/get_or_create_user.dart';
import '../../domain/usecases/get_study_progress.dart';
import '../../domain/usecases/get_user_statistics.dart';

enum StatisticsPeriod {
  sevenDays,
  thirtyDays,
  allTime,
}

class StatisticsProvider extends ChangeNotifier {
  StatisticsProvider({
    required GetOrCreateUser getOrCreateUser,
    required GetUserStatistics getUserStatistics,
    required GetStudyProgress getStudyProgress,
  })  : _getOrCreateUser = getOrCreateUser,
        _getUserStatistics = getUserStatistics,
        _getStudyProgress = getStudyProgress;

  final GetOrCreateUser _getOrCreateUser;
  final GetUserStatistics _getUserStatistics;
  final GetStudyProgress _getStudyProgress;

  UserStatistics? _statistics;
  StudyProgress? _progress;
  StatisticsPeriod _selectedPeriod = StatisticsPeriod.thirtyDays;
  bool _isLoading = false;
  String? _errorMessage;

  UserStatistics? get statistics => _statistics;
  StudyProgress? get progressData => _progress;
  StatisticsPeriod get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalAnswered => _statistics?.totalAnswered ?? 0;
  int get totalCorrect => _statistics?.totalCorrect ?? 0;
  int get currentStreak => _progress?.currentStreak ?? 0;
  int get weeklyAnsweredQuestions => _progress?.weeklyAnsweredQuestions ?? 0;
  int get weeklyGoalQuestions => _progress?.weeklyGoalQuestions ?? 50;
  double get weeklyGoalProgress => _progress?.weeklyProgressRate ?? 0;
  double get accuracyRate => _statistics?.accuracyRate ?? 0;
  Map<String, double> get accuracyBySubject =>
      _statistics?.accuracyBySubject ?? const <String, double>{};
  List<Map<String, dynamic>> get weeklyProgress =>
      _statistics?.weeklyProgress ?? const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> get topStudyLocations =>
      _statistics?.topStudyLocations ?? const <Map<String, dynamic>>[];

  Future<void> loadStatistics(int userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _getOrCreateUser();
      _statistics = await _getUserStatistics(user.id ?? userId);
      _progress = await _getStudyProgress();
      if (_statistics == null) {
        _errorMessage = 'Estatisticas nao encontradas.';
      }
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar estatisticas.';
    } finally {
      _setLoading(false);
    }
  }

  void setPeriod(StatisticsPeriod period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  String periodLabel(StatisticsPeriod period) {
    switch (period) {
      case StatisticsPeriod.sevenDays:
        return 'Ultimos 7 dias';
      case StatisticsPeriod.thirtyDays:
        return 'Ultimos 30 dias';
      case StatisticsPeriod.allTime:
        return 'Tudo';
    }
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
