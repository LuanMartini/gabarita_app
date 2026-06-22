class DbConstants {
  DbConstants._();

  static const String databaseName = 'gabarita.db';
  static const int databaseVersion = 1;

  static const String tableUsers = 'users';
  static const String tableQuestions = 'questions';
  static const String tableAttempts = 'attempts';
  static const String tableStudySessions = 'study_sessions';

  static const String colUserId = 'id';
  static const String colUserName = 'name';
  static const String colUserAvatar = 'avatar';
  static const String colUserCreatedAt = 'created_at';
  static const String colUserCurrentStreak = 'current_streak';
  static const String colUserMaxStreak = 'max_streak';
  static const String colUserTotalAnswered = 'total_answered';
  static const String colUserTotalCorrect = 'total_correct';
  static const String colUserStudyGoalMinutes = 'study_goal_minutes';
  static const String colUserNotificationsEnabled = 'notifications_enabled';
  static const String colUserNotificationHour = 'notification_hour';
  static const String colUserNotificationMinute = 'notification_minute';

  static const String colQuestionId = 'id';
  static const String colQuestionText = 'question_text';
  static const String colQuestionSubject = 'subject';
  static const String colQuestionTopic = 'topic';
  static const String colQuestionDifficulty = 'difficulty';
  static const String colQuestionYear = 'year';
  static const String colQuestionExamSource = 'exam_source';
  static const String colQuestionOptionA = 'option_a';
  static const String colQuestionOptionB = 'option_b';
  static const String colQuestionOptionC = 'option_c';
  static const String colQuestionOptionD = 'option_d';
  static const String colQuestionOptionE = 'option_e';
  static const String colQuestionCorrectOption = 'correct_option';
  static const String colQuestionExplanation = 'explanation';
  static const String colQuestionImagePath = 'image_path';
  static const String colQuestionIsFavorite = 'is_favorite';
  static const String colQuestionCreatedAt = 'created_at';

  static const String colAttemptId = 'id';
  static const String colAttemptUserId = 'user_id';
  static const String colAttemptQuestionId = 'question_id';
  static const String colAttemptSessionId = 'session_id';
  static const String colAttemptSelectedOption = 'selected_option';
  static const String colAttemptIsCorrect = 'is_correct';
  static const String colAttemptTimeTakenSeconds = 'time_taken_seconds';
  static const String colAttemptLatitude = 'latitude';
  static const String colAttemptLongitude = 'longitude';
  static const String colAttemptLocationName = 'location_name';
  static const String colAttemptAnsweredAt = 'answered_at';

  static const String colSessionId = 'id';
  static const String colSessionUserId = 'user_id';
  static const String colSessionType = 'type';
  static const String colSessionSubjectsJson = 'subjects_json';
  static const String colSessionTotalQuestions = 'total_questions';
  static const String colSessionCorrectCount = 'correct_count';
  static const String colSessionDurationSeconds = 'duration_seconds';
  static const String colSessionLatitude = 'latitude';
  static const String colSessionLongitude = 'longitude';
  static const String colSessionLocationName = 'location_name';
  static const String colSessionStartedAt = 'started_at';
  static const String colSessionFinishedAt = 'finished_at';
}
