import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/datasources/local/database_helper.dart';
import 'package:gabarita_app/data/repositories/user_repository_impl.dart';
import 'package:gabarita_app/domain/entities/attempt.dart';
import 'package:gabarita_app/domain/entities/question.dart';
import 'package:gabarita_app/domain/entities/study_session.dart';
import 'package:gabarita_app/domain/entities/user.dart';
import 'package:gabarita_app/domain/usecases/update_user_avatar.dart';
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

  test('atualiza somente a foto do perfil local', () async {
    final db = DatabaseHelper.instance;
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final userId = await db.insertUser(
      User(
        name: 'Usuario avatar $suffix',
        currentStreak: 3,
        totalAnswered: 8,
        totalCorrect: 6,
      ),
    );

    expect(
      await db.updateUserAvatar(
        userId: userId,
        avatarPath: 'profile_photos/avatar_$suffix.jpg',
      ),
      1,
    );

    final user = await db.getUser(userId);
    expect(user?.avatar, 'profile_photos/avatar_$suffix.jpg');
    expect(user?.name, 'Usuario avatar $suffix');
    expect(user?.currentStreak, 3);
    expect(user?.totalAnswered, 8);
    expect(user?.totalCorrect, 6);
  });

  test('persiste foto do perfil como imagem inline no SQLite', () async {
    final db = DatabaseHelper.instance;
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final avatarData = 'data:image/jpeg;base64,/9j/avatar_$suffix';
    final userId = await db.insertUser(
      User(name: 'Usuario foto inline $suffix'),
    );

    expect(
      await db.updateUserAvatar(
        userId: userId,
        avatarPath: avatarData,
      ),
      1,
    );

    final user = await db.getUser(userId);
    expect(user?.avatar, avatarData);
  });

  test('troca, remove e salva nova foto pelo use case de avatar', () async {
    final db = DatabaseHelper.instance;
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final updateAvatar = UpdateUserAvatar(UserRepositoryImpl(db));
    final userId = await db.insertUser(
      User(name: 'Usuario troca foto $suffix'),
    );
    final firstAvatar = 'data:image/jpeg;base64,primeira_$suffix';
    final secondAvatar = 'data:image/jpeg;base64,segunda_$suffix';

    final firstUpdate = await updateAvatar(
      userId: userId,
      avatarPath: firstAvatar,
    );
    expect(firstUpdate.avatar, firstAvatar);

    final removed = await updateAvatar(userId: userId, avatarPath: null);
    expect(removed.avatar, isNull);

    final secondUpdate = await updateAvatar(
      userId: userId,
      avatarPath: secondAvatar,
    );
    expect(secondUpdate.avatar, secondAvatar);

    final persistedUser = await db.getUser(userId);
    expect(persistedUser?.avatar, secondAvatar);
  });
}
