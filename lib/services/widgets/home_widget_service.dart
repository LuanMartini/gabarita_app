import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../../data/datasources/local/database_helper.dart';
import '../../data/repositories/attempt_repository_impl.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/attempt.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/get_or_create_user.dart';
import '../../domain/usecases/save_attempt.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static const String _dailyQuestionIdSettingKey = 'widget_daily_question_id';
  static const String _dailyAnsweredSettingKey = 'widget_daily_answered';
  static const String _dailySelectedSettingKey = 'widget_daily_selected_option';
  static const String _dailyResultSettingKey = 'widget_daily_result';

  static const List<String> _androidWidgetNames = [
    'DailyChallengeWidgetProvider',
    'PerformanceWidgetProvider',
    'QuickStatsWidgetProvider',
    'LastTopicWidgetProvider',
    'ScannerWidgetProvider',
  ];

  static Future<void> initialize({int userId = 1}) async {
    await HomeWidget.registerInteractivityCallback(gabaritaHomeWidgetCallback);
    await refreshWidgets(userId: userId);
  }

  static Future<void> refreshWidgets({int userId = 1}) async {
    try {
      final db = DatabaseHelper.instance;
      final questionRepository = QuestionRepositoryImpl(dbHelper: db);
      final user = await GetOrCreateUser(UserRepositoryImpl(db))();
      final resolvedUserId = user.id ?? userId;
      final dailyQuestion = await questionRepository.getDailyChallenge(
        resolvedUserId,
      );
      final todayCount = await db.getTodayAnsweredCount(resolvedUserId);
      final weeklySeries = await db.getWeeklyAccuracyPercentages(
        resolvedUserId,
      );
      final lastTopic = await db.getLastStudiedTopic(resolvedUserId);
      final bestLocation = await db.getBestStudyLocationComparison(
        resolvedUserId,
      );

      await Future.wait([
        _saveDailyChallenge(dailyQuestion, userId: resolvedUserId),
        _saveQuickStats(
          totalAnswered: user.totalAnswered,
          accuracyRate: user.accuracyRate,
          todayCount: todayCount,
        ),
        _savePerformance(weeklySeries),
        _saveLastTopic(lastTopic),
        _saveStudyLocation(bestLocation),
      ]);

      await updateAllWidgets();
    } catch (_) {
      // Widgets should never block the core study flow.
    }
  }

  static Future<void> updateAllWidgets() async {
    for (final widgetName in _androidWidgetNames) {
      try {
        await HomeWidget.updateWidget(androidName: widgetName);
      } catch (_) {
        // The provider may not exist on the current platform.
      }
    }
  }

  static Future<void> handleBackgroundUri(Uri? uri) async {
    if (uri == null || uri.host != 'daily-answer') return;

    final selected = uri.queryParameters['selected']?.toUpperCase();
    final db = DatabaseHelper.instance;
    final questionId = int.tryParse(
          await db.getAppSetting(_dailyQuestionIdSettingKey) ?? '',
        ) ??
        0;
    final alreadyAnswered =
        await db.getAppSetting(_dailyAnsweredSettingKey) == 'true';
    final question =
        questionId > 0 ? await db.getQuestionById(questionId) : null;
    final correct = question?.correctOption.toUpperCase();

    if (selected == null ||
        correct == null ||
        correct.isEmpty ||
        alreadyAnswered) {
      return;
    }

    final isCorrect = selected == correct;
    await _saveWidgetAttempt(
      questionId: questionId,
      selectedOption: selected,
      isCorrect: isCorrect,
    );
    await db.setAppSetting(_dailySelectedSettingKey, selected);
    await db.setAppSetting(
      _dailyResultSettingKey,
      isCorrect
          ? 'Voce acertou direto pelo widget.'
          : 'Resposta $selected. Gabarito: $correct.',
    );
    await db.setAppSetting(_dailyAnsweredSettingKey, 'true');
    await HomeWidget.saveWidgetData<String>('daily_selected_option', selected);
    await HomeWidget.saveWidgetData<String>(
      'daily_result',
      isCorrect
          ? 'Voce acertou direto pelo widget.'
          : 'Resposta $selected. Gabarito: $correct.',
    );
    await HomeWidget.saveWidgetData<bool>('daily_answered', true);
    await _saveDerivedStats();

    try {
      await HomeWidget.updateWidget(
        androidName: 'DailyChallengeWidgetProvider',
      );
      await HomeWidget.updateWidget(androidName: 'QuickStatsWidgetProvider');
    } catch (_) {}
  }

  static Future<void> _saveDailyChallenge(
    Question? question, {
    required int userId,
  }) async {
    final questionId = question?.id ?? 0;
    final db = DatabaseHelper.instance;
    await db.setAppSetting(_dailyQuestionIdSettingKey, '$questionId');
    await db.setAppSetting(_dailyAnsweredSettingKey, 'false');
    await db.setAppSetting(_dailySelectedSettingKey, '');
    await db.setAppSetting(_dailyResultSettingKey, '');

    await HomeWidget.saveWidgetData<int>(
      'daily_question_id',
      questionId,
    );
    await HomeWidget.saveWidgetData<int>('daily_user_id', userId);
    await HomeWidget.saveWidgetData<String>(
      'daily_subject',
      question?.subject ?? 'Desafio do Dia',
    );
    await HomeWidget.saveWidgetData<String>(
      'daily_topic',
      question?.topic ?? 'Banco local',
    );
    await HomeWidget.saveWidgetData<String>(
      'daily_question',
      _compact(
        question?.text ??
            'Abra o Gabarita para gerar uma questao assim que o banco carregar.',
        maxLength: 150,
      ),
    );
    await HomeWidget.saveWidgetData<String>(
      'daily_option_a',
      _compact(question?.optionA ?? 'A', maxLength: 42),
    );
    await HomeWidget.saveWidgetData<String>(
      'daily_option_b',
      _compact(question?.optionB ?? 'B', maxLength: 42),
    );
    await HomeWidget.saveWidgetData<String>(
      'daily_option_c',
      _compact(question?.optionC ?? 'C', maxLength: 42),
    );
    await HomeWidget.saveWidgetData<String>(
      'daily_option_d',
      _compact(question?.optionD ?? 'D', maxLength: 42),
    );
    await HomeWidget.saveWidgetData<String>(
      'daily_correct_option',
      question?.correctOption.toUpperCase() ?? '',
    );
    await HomeWidget.saveWidgetData<bool>('daily_answered', false);
    await HomeWidget.saveWidgetData<String>('daily_selected_option', '');
    await HomeWidget.saveWidgetData<String>('daily_result', '');
  }

  static Future<void> _saveWidgetAttempt({
    required int questionId,
    required String selectedOption,
    required bool isCorrect,
  }) async {
    if (questionId <= 0) return;

    final db = DatabaseHelper.instance;
    final user = await GetOrCreateUser(UserRepositoryImpl(db))();
    final userId = user.id ?? 1;
    await HomeWidget.saveWidgetData<int>('daily_user_id', userId);

    final saveAttempt = SaveAttempt(AttemptRepositoryImpl(db));
    await saveAttempt(
      Attempt(
        userId: userId,
        questionId: questionId,
        sessionId: 'widget-daily',
        selectedOption: selectedOption,
        isCorrect: isCorrect,
        timeTakenSeconds: 0,
        locationName: 'Widget',
      ),
    );
  }

  static Future<void> _saveDerivedStats() async {
    final db = DatabaseHelper.instance;
    final user = await GetOrCreateUser(UserRepositoryImpl(db))();
    final userId = user.id ?? 1;
    final reloadedUser = await db.getUser(userId) ?? user;
    final todayCount = await db.getTodayAnsweredCount(userId);
    final weeklySeries = await db.getWeeklyAccuracyPercentages(userId);
    final lastTopic = await db.getLastStudiedTopic(userId);
    final bestLocation = await db.getBestStudyLocationComparison(userId);

    await Future.wait([
      _saveQuickStats(
        totalAnswered: reloadedUser.totalAnswered,
        accuracyRate: reloadedUser.accuracyRate,
        todayCount: todayCount,
      ),
      _savePerformance(weeklySeries),
      _saveLastTopic(lastTopic),
      _saveStudyLocation(bestLocation),
    ]);
  }

  static Future<void> _saveQuickStats({
    required int totalAnswered,
    required double accuracyRate,
    required int todayCount,
  }) async {
    await HomeWidget.saveWidgetData<int>('quick_total_answered', totalAnswered);
    await HomeWidget.saveWidgetData<int>(
      'quick_accuracy_percent',
      (accuracyRate * 100).round(),
    );
    await HomeWidget.saveWidgetData<int>('quick_today_count', todayCount);
  }

  static Future<void> _savePerformance(List<int> weeklySeries) async {
    final normalized = weeklySeries.length == 7
        ? weeklySeries
        : List<int>.filled(7, 0, growable: false);
    await HomeWidget.saveWidgetData<String>(
      'weekly_accuracy_series',
      normalized.map((value) => value.clamp(0, 100)).join(','),
    );
    await HomeWidget.saveWidgetData<int>(
      'weekly_accuracy_latest',
      normalized.isEmpty ? 0 : normalized.last,
    );
  }

  static Future<void> _saveLastTopic(Map<String, dynamic>? row) async {
    await HomeWidget.saveWidgetData<String>(
      'last_topic',
      row?['topic']?.toString() ?? 'Nenhum topico ainda',
    );
    await HomeWidget.saveWidgetData<String>(
      'last_subject',
      row?['subject']?.toString() ?? 'Comece respondendo uma questao',
    );
    await HomeWidget.saveWidgetData<String>(
      'last_exam_source',
      row?['exam_source']?.toString() ?? 'Banco local',
    );
  }

  static Future<void> _saveStudyLocation(Map<String, dynamic>? row) async {
    final accuracy = _asDouble(row?['accuracy']);
    final delta = _asDouble(row?['comparison_delta']);
    await HomeWidget.saveWidgetData<String>(
      'best_location',
      row?['location']?.toString() ?? 'Sem local registrado',
    );
    await HomeWidget.saveWidgetData<int>(
      'best_location_accuracy',
      (accuracy * 100).round(),
    );
    await HomeWidget.saveWidgetData<String>(
      'best_location_comparison',
      delta == 0
          ? 'Ative o GPS ao responder.'
          : '${(delta * 100).round()}% melhor que ${row?['comparison_location']}',
    );
  }

  static String _compact(String value, {required int maxLength}) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength - 1)}...';
  }

  static double _asDouble(Object? value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

@pragma('vm:entry-point')
FutureOr<void> gabaritaHomeWidgetCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidgetService.handleBackgroundUri(uri);
}
