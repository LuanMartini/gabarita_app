import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/study_progress.dart';
import '../../domain/repositories/i_study_progress_repository.dart';

class StudyProgressRepositoryImpl implements IStudyProgressRepository {
  static const String _currentStreakKey = 'study_progress_current_streak';
  static const String _maxStreakKey = 'study_progress_max_streak';
  static const String _weeklyGoalKey = 'study_progress_weekly_goal_questions';
  static const String _weeklyAnsweredKey =
      'study_progress_weekly_answered_questions';
  static const String _lastStudyDateKey = 'study_progress_last_study_date';
  static const String _weekStartedAtKey = 'study_progress_week_started_at';

  @override
  Future<StudyProgress> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progress = _readProgress(prefs);
    final normalized = _resetWeekIfNeeded(progress, DateTime.now());
    if (normalized.weekStartedAt != progress.weekStartedAt ||
        normalized.weeklyAnsweredQuestions !=
            progress.weeklyAnsweredQuestions) {
      await _writeProgress(prefs, normalized);
    }
    return normalized;
  }

  @override
  Future<StudyProgress> recordAnsweredQuestion({
    DateTime? answeredAt,
  }) async {
    final now = answeredAt ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final current = _resetWeekIfNeeded(_readProgress(prefs), now);
    final previousStudyDay = current.lastStudyDate;
    final alreadyStudiedToday =
        previousStudyDay != null && _isSameDate(previousStudyDay, now);

    final nextStreak = alreadyStudiedToday
        ? current.currentStreak
        : _isYesterday(previousStudyDay, now)
            ? current.currentStreak + 1
            : 1;

    final next = current.copyWith(
      currentStreak: nextStreak,
      maxStreak: max(current.maxStreak, nextStreak),
      weeklyAnsweredQuestions: current.weeklyAnsweredQuestions + 1,
      lastStudyDate: now,
      weekStartedAt: _startOfWeek(now),
    );

    await _writeProgress(prefs, next);
    return next;
  }

  @override
  Future<StudyProgress> setWeeklyGoalQuestions(int value) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getProgress();
    final next = current.copyWith(
      weeklyGoalQuestions: value.clamp(1, 999).toInt(),
    );
    await _writeProgress(prefs, next);
    return next;
  }

  @override
  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_maxStreakKey);
    await prefs.remove(_weeklyGoalKey);
    await prefs.remove(_weeklyAnsweredKey);
    await prefs.remove(_lastStudyDateKey);
    await prefs.remove(_weekStartedAtKey);
  }

  StudyProgress _readProgress(SharedPreferences prefs) {
    return StudyProgress(
      currentStreak: prefs.getInt(_currentStreakKey) ?? 0,
      maxStreak: prefs.getInt(_maxStreakKey) ?? 0,
      weeklyGoalQuestions: prefs.getInt(_weeklyGoalKey) ?? 50,
      weeklyAnsweredQuestions: prefs.getInt(_weeklyAnsweredKey) ?? 0,
      lastStudyDate: _readDate(prefs.getString(_lastStudyDateKey)),
      weekStartedAt: _readDate(prefs.getString(_weekStartedAtKey)),
    );
  }

  Future<void> _writeProgress(
    SharedPreferences prefs,
    StudyProgress progress,
  ) async {
    await prefs.setInt(_currentStreakKey, progress.currentStreak);
    await prefs.setInt(_maxStreakKey, progress.maxStreak);
    await prefs.setInt(_weeklyGoalKey, progress.weeklyGoalQuestions);
    await prefs.setInt(
      _weeklyAnsweredKey,
      progress.weeklyAnsweredQuestions,
    );

    final lastStudyDate = progress.lastStudyDate;
    if (lastStudyDate == null) {
      await prefs.remove(_lastStudyDateKey);
    } else {
      await prefs.setString(_lastStudyDateKey, lastStudyDate.toIso8601String());
    }

    final weekStartedAt = progress.weekStartedAt;
    if (weekStartedAt == null) {
      await prefs.remove(_weekStartedAtKey);
    } else {
      await prefs.setString(_weekStartedAtKey, weekStartedAt.toIso8601String());
    }
  }

  StudyProgress _resetWeekIfNeeded(StudyProgress progress, DateTime now) {
    final currentWeekStart = _startOfWeek(now);
    final storedWeekStart = progress.weekStartedAt;
    if (storedWeekStart != null &&
        _isSameDate(storedWeekStart, currentWeekStart)) {
      return progress;
    }

    return progress.copyWith(
      weeklyAnsweredQuestions: 0,
      weekStartedAt: currentWeekStart,
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  DateTime? _readDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isYesterday(DateTime? previous, DateTime now) {
    if (previous == null) return false;
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    return _isSameDate(previous, yesterday);
  }
}
