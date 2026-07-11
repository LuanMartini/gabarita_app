import '../../domain/entities/study_progress.dart';
import '../../domain/repositories/i_study_progress_repository.dart';
import '../datasources/local/database_helper.dart';

/// Persiste o progresso do único perfil local exclusivamente no SQLite.
class StudyProgressRepositoryImpl implements IStudyProgressRepository {
  StudyProgressRepositoryImpl([DatabaseHelper? dbHelper])
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  @override
  Future<StudyProgress> getProgress() async {
    final user = await _dbHelper.getFirstUser();
    if (user?.id == null) return StudyProgress.initial();
    return _dbHelper.getStudyProgress(user!.id!);
  }

  @override
  Future<StudyProgress> recordAnsweredQuestion({DateTime? answeredAt}) async {
    final user = await _dbHelper.getFirstUser();
    if (user?.id == null) {
      throw StateError('Nao existe perfil local para registrar o progresso.');
    }
    return _dbHelper.recordAnsweredQuestion(
      userId: user!.id!,
      answeredAt: answeredAt,
    );
  }

  @override
  Future<StudyProgress> setWeeklyGoalQuestions(int value) async {
    final user = await _dbHelper.getFirstUser();
    if (user?.id == null) {
      throw StateError('Nao existe perfil local para atualizar a meta.');
    }
    return _dbHelper.setWeeklyGoalQuestions(userId: user!.id!, value: value);
  }

  @override
  Future<void> clearProgress() async {
    final user = await _dbHelper.getFirstUser();
    if (user?.id != null) {
      await _dbHelper.clearStudyProgress(user!.id!);
    }
  }
}
