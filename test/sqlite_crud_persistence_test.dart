import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/datasources/local/database_helper.dart';
import 'package:gabarita_app/domain/entities/attempt.dart';
import 'package:gabarita_app/domain/entities/question.dart';
import 'package:gabarita_app/domain/entities/study_session.dart';
import 'package:gabarita_app/domain/entities/user.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('persiste CRUD e dados derivados em uma transação SQLite', () async {
    final db = DatabaseHelper.instance;
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final userId = await db.insertUser(User(name: 'Teste $suffix'));
    final questionId = await db.insertQuestion(
      Question(
        text: 'Questão local $suffix',
        subject: 'Matematica',
        topic: 'Topico $suffix',
        examSource: 'Teste local',
        optionA: 'A',
        optionB: 'B',
        optionC: 'C',
        optionD: 'D',
        correctOption: 'A',
      ),
    );

    expect(await db.toggleFavorite(questionId, true), 1);
    expect((await db.getFavoriteQuestions()).any((q) => q.id == questionId),
        isTrue);

    final attemptId = await db.insertAttempt(
      Attempt(
        userId: userId,
        questionId: questionId,
        sessionId: 'session-$suffix',
        selectedOption: 'A',
        isCorrect: true,
      ),
    );
    expect(attemptId, greaterThan(0));

    final persistedUser = await db.getUser(userId);
    final progress = await db.getStudyProgress(userId);
    expect(persistedUser?.totalAnswered, 1);
    expect(persistedUser?.totalCorrect, 1);
    expect(progress.weeklyAnsweredQuestions, 1);
    expect(progress.currentStreak, 1);

    await db.insertStudySession(
      StudySession(
        id: 'session-$suffix',
        userId: userId,
        type: StudySessionType.simulado,
        totalQuestions: 1,
        correctCount: 1,
        finishedAt: DateTime.now(),
      ),
    );
    expect((await db.getStudySessionsByUser(userId)).length, 1);

    await db.clearUserData(userId);
    final clearedUser = await db.getUser(userId);
    expect(clearedUser?.totalAnswered, 0);
    expect((await db.getAttemptsByUser(userId)), isEmpty);
    final clearedProgress = await db.getStudyProgress(userId);
    expect(clearedProgress.weeklyAnsweredQuestions, 0);
    expect(clearedProgress.currentStreak, 0);
  });

  test('atualiza somente o nome do perfil local', () async {
    final db = DatabaseHelper.instance;
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final userId = await db.insertUser(
      User(
        name: 'Nome original $suffix',
        currentStreak: 4,
        totalAnswered: 12,
        totalCorrect: 9,
        studyGoalMinutes: 45,
      ),
    );

    expect(
      await db.updateUserName(userId: userId, name: 'Nome atualizado'),
      1,
    );

    final user = await db.getUser(userId);
    expect(user?.name, 'Nome atualizado');
    expect(user?.currentStreak, 4);
    expect(user?.totalAnswered, 12);
    expect(user?.totalCorrect, 9);
    expect(user?.studyGoalMinutes, 45);
  });
}
