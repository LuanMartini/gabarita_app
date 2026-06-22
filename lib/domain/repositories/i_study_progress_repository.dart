import '../entities/study_progress.dart';

abstract class IStudyProgressRepository {
  Future<StudyProgress> getProgress();

  Future<StudyProgress> recordAnsweredQuestion({
    DateTime? answeredAt,
  });

  Future<StudyProgress> setWeeklyGoalQuestions(int value);

  Future<void> clearProgress();
}
