import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int dailyStudyReminderId = 1001;
  static const String _dailyChannelId = 'daily_study_reminder';
  static const String _dailyChannelName = 'Lembrete diario de estudo';
  static const String _dailyChannelDescription =
      'Lembretes offline para manter a rotina de estudos.';
  static const String _reviewChannelId = 'wrong_question_review';
  static const String _reviewChannelName = 'Revisao de erros';
  static const String _reviewChannelDescription =
      'Lembretes espacados para revisar questoes erradas.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize({
    String timeZoneName = 'America/Sao_Paulo',
  }) async {
    _configureTimeZone(timeZoneName);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initializationSettings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> scheduleDailyStudyReminder({
    int id = dailyStudyReminderId,
    int hour = 19,
    int minute = 0,
    String title = 'Hora de estudar',
    String body = 'Resolva algumas questoes hoje e mantenha sua sequencia.',
    String? payload,
  }) async {
    await _ensureInitialized();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextDailyOccurrence(hour: hour, minute: minute),
      _dailyNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancelDailyStudyReminder({
    int id = dailyStudyReminderId,
  }) async {
    await _ensureInitialized();
    await _plugin.cancel(id);
  }

  Future<void> scheduleWrongQuestionReview({
    required int questionId,
    required String questionTopic,
    Duration delay = const Duration(hours: 6),
  }) async {
    await _ensureInitialized();

    await _plugin.zonedSchedule(
      2000 + questionId,
      'Revisar erro',
      'Volte em $questionTopic para fixar o conteudo.',
      tz.TZDateTime.now(tz.local).add(delay),
      _reviewNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'review:$questionId',
    );
  }

  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  NotificationDetails _dailyNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _dailyChannelId,
      _dailyChannelName,
      channelDescription: _dailyChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const darwinDetails = DarwinNotificationDetails();

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  NotificationDetails _reviewNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _reviewChannelId,
      _reviewChannelName,
      channelDescription: _reviewChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const darwinDetails = DarwinNotificationDetails();

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  tz.TZDateTime _nextDailyOccurrence({
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  void _configureTimeZone(String timeZoneName) {
    tz_data.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
