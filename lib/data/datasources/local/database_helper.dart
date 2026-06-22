// ============================================================
//  database_helper.dart
//  Gabarita · SQLite Database Helper (Singleton)
//  Tabelas: users · questions · attempts · study_sessions
// ============================================================

import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/db_constants.dart';
import '../../../domain/entities/entities.dart';
import '../../models/models.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // ── Abertura / criação do banco ───────────────────────────
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.databaseName);

    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Activa chaves estrangeiras no SQLite
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  //  CRIAÇÃO DAS TABELAS (v1)
  // ──────────────────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    await _createTableUsers(db);
    await _createTableQuestions(db);
    await _createTableAttempts(db);
    await _createTableStudySessions(db);
    await _createIndexes(db);
    await _seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrações futuras serão adicionadas aqui por versão
    // Exemplo: if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }

  // ─────────────────────────────────────────────────────────
  //  DDL · Tabela: users
  // ─────────────────────────────────────────────────────────
  Future<void> _createTableUsers(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableUsers} (
        ${DbConstants.colUserId}                INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colUserName}              TEXT    NOT NULL,
        ${DbConstants.colUserAvatar}            TEXT,
        ${DbConstants.colUserCreatedAt}         TEXT    NOT NULL,
        ${DbConstants.colUserCurrentStreak}     INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colUserMaxStreak}         INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colUserTotalAnswered}     INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colUserTotalCorrect}      INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colUserStudyGoalMinutes}  INTEGER NOT NULL DEFAULT 30,
        ${DbConstants.colUserNotificationsEnabled} INTEGER NOT NULL DEFAULT 1,
        ${DbConstants.colUserNotificationHour}  INTEGER NOT NULL DEFAULT 19,
        ${DbConstants.colUserNotificationMinute} INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ─────────────────────────────────────────────────────────
  //  DDL · Tabela: questions
  // ─────────────────────────────────────────────────────────
  Future<void> _createTableQuestions(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableQuestions} (
        ${DbConstants.colQuestionId}            INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colQuestionText}          TEXT    NOT NULL,
        ${DbConstants.colQuestionSubject}       TEXT    NOT NULL,
        ${DbConstants.colQuestionTopic}         TEXT    NOT NULL,
        ${DbConstants.colQuestionDifficulty}    INTEGER NOT NULL DEFAULT 2,
        ${DbConstants.colQuestionYear}          INTEGER,
        ${DbConstants.colQuestionExamSource}    TEXT,
        ${DbConstants.colQuestionOptionA}       TEXT    NOT NULL,
        ${DbConstants.colQuestionOptionB}       TEXT    NOT NULL,
        ${DbConstants.colQuestionOptionC}       TEXT    NOT NULL,
        ${DbConstants.colQuestionOptionD}       TEXT    NOT NULL,
        ${DbConstants.colQuestionOptionE}       TEXT,
        ${DbConstants.colQuestionCorrectOption} TEXT    NOT NULL CHECK(correct_option IN ('A','B','C','D','E')),
        ${DbConstants.colQuestionExplanation}   TEXT,
        ${DbConstants.colQuestionImagePath}     TEXT,
        ${DbConstants.colQuestionIsFavorite}    INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colQuestionCreatedAt}     TEXT    NOT NULL
      )
    ''');
  }

  // ─────────────────────────────────────────────────────────
  //  DDL · Tabela: attempts
  // ─────────────────────────────────────────────────────────
  Future<void> _createTableAttempts(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableAttempts} (
        ${DbConstants.colAttemptId}             INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colAttemptUserId}         INTEGER NOT NULL REFERENCES ${DbConstants.tableUsers}(id) ON DELETE CASCADE,
        ${DbConstants.colAttemptQuestionId}     INTEGER NOT NULL REFERENCES ${DbConstants.tableQuestions}(id) ON DELETE CASCADE,
        ${DbConstants.colAttemptSessionId}      TEXT    NOT NULL,
        ${DbConstants.colAttemptSelectedOption} TEXT    NOT NULL,
        ${DbConstants.colAttemptIsCorrect}      INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colAttemptTimeTakenSeconds} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colAttemptLatitude}       REAL,
        ${DbConstants.colAttemptLongitude}      REAL,
        ${DbConstants.colAttemptLocationName}   TEXT,
        ${DbConstants.colAttemptAnsweredAt}     TEXT    NOT NULL
      )
    ''');
  }

  // ─────────────────────────────────────────────────────────
  //  DDL · Tabela: study_sessions
  // ─────────────────────────────────────────────────────────
  Future<void> _createTableStudySessions(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableStudySessions} (
        ${DbConstants.colSessionId}             TEXT    PRIMARY KEY,
        ${DbConstants.colSessionUserId}         INTEGER NOT NULL REFERENCES ${DbConstants.tableUsers}(id) ON DELETE CASCADE,
        ${DbConstants.colSessionType}           TEXT    NOT NULL DEFAULT 'free',
        ${DbConstants.colSessionSubjectsJson}   TEXT    NOT NULL DEFAULT '[]',
        ${DbConstants.colSessionTotalQuestions} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colSessionCorrectCount}   INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colSessionDurationSeconds} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colSessionLatitude}       REAL,
        ${DbConstants.colSessionLongitude}      REAL,
        ${DbConstants.colSessionLocationName}   TEXT,
        ${DbConstants.colSessionStartedAt}      TEXT    NOT NULL,
        ${DbConstants.colSessionFinishedAt}     TEXT
      )
    ''');
  }

  // ─────────────────────────────────────────────────────────
  //  DDL · Índices para performance
  // ─────────────────────────────────────────────────────────
  Future<void> _createIndexes(Database db) async {
    // Questões: busca por matéria e dificuldade são os filtros mais comuns
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_questions_subject
        ON ${DbConstants.tableQuestions}(${DbConstants.colQuestionSubject})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_questions_difficulty
        ON ${DbConstants.tableQuestions}(${DbConstants.colQuestionDifficulty})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_questions_favorite
        ON ${DbConstants.tableQuestions}(${DbConstants.colQuestionIsFavorite})
    ''');

    // Attempts: ordenar por data e filtrar por sessão
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attempts_user_date
        ON ${DbConstants.tableAttempts}(${DbConstants.colAttemptUserId}, ${DbConstants.colAttemptAnsweredAt})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attempts_session
        ON ${DbConstants.tableAttempts}(${DbConstants.colAttemptSessionId})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attempts_question
        ON ${DbConstants.tableAttempts}(${DbConstants.colAttemptQuestionId})
    ''');
  }

  // ──────────────────────────────────────────────────────────
  //  SEED · Questões de exemplo para demonstração
  // ──────────────────────────────────────────────────────────
  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();
    final seedQuestions = [
      {
        'question_text':
            'Qual foi o principal movimento histórico responsável pela abolição da escravatura no Brasil?',
        'subject': 'História',
        'topic': 'Brasil Império',
        'difficulty': 2,
        'year': 2019,
        'exam_source': 'ENEM',
        'option_a': 'Inconfidência Mineira',
        'option_b': 'Movimento Abolicionista',
        'option_c': 'Proclamação da República',
        'option_d': 'Revolução Farroupilha',
        'option_e': 'Guerra do Paraguai',
        'correct_option': 'B',
        'explanation':
            'O Movimento Abolicionista foi um conjunto de ações políticas e sociais que pressionou o governo imperial até a assinatura da Lei Áurea em 1888.',
        'image_path': null,
        'is_favorite': 0,
        'created_at': now,
      },
      {
        'question_text':
            'Em uma equação do 2º grau ax² + bx + c = 0, com a=1, b=-5 e c=6, quais são as raízes?',
        'subject': 'Matemática',
        'topic': 'Equações do 2º Grau',
        'difficulty': 1,
        'year': 2020,
        'exam_source': 'ENEM',
        'option_a': 'x=1 e x=6',
        'option_b': 'x=2 e x=3',
        'option_c': 'x=-2 e x=-3',
        'option_d': 'x=0 e x=5',
        'option_e': null,
        'correct_option': 'B',
        'explanation':
            'Usando a fórmula de Bhaskara: Δ = 25 - 24 = 1. x = (5±1)/2, logo x₁=3 e x₂=2.',
        'image_path': null,
        'is_favorite': 0,
        'created_at': now,
      },
      {
        'question_text':
            'Qual organela celular é responsável pela produção de energia (ATP) nas células eucarióticas?',
        'subject': 'Biologia',
        'topic': 'Célula e Organelas',
        'difficulty': 1,
        'year': 2021,
        'exam_source': 'FUVEST',
        'option_a': 'Ribossomo',
        'option_b': 'Núcleo',
        'option_c': 'Mitocôndria',
        'option_d': 'Lisossomo',
        'option_e': 'Aparelho de Golgi',
        'correct_option': 'C',
        'explanation':
            'A mitocôndria é a "usina energética" da célula, responsável pela respiração celular aeróbica e produção de ATP.',
        'image_path': null,
        'is_favorite': 0,
        'created_at': now,
      },
      {
        'question_text':
            'Qual figura de linguagem está presente no verso "A vida é uma ilusão que a morte acorda"?',
        'subject': 'Português',
        'topic': 'Figuras de Linguagem',
        'difficulty': 2,
        'year': 2022,
        'exam_source': 'ENEM',
        'option_a': 'Metonímia',
        'option_b': 'Hipérbole',
        'option_c': 'Metáfora',
        'option_d': 'Onomatopeia',
        'option_e': 'Eufemismo',
        'correct_option': 'C',
        'explanation':
            'A metáfora é uma comparação implícita entre dois elementos. Aqui, a vida é comparada a uma ilusão sem uso do "como".',
        'image_path': null,
        'is_favorite': 0,
        'created_at': now,
      },
      {
        'question_text':
            'Qual é o principal gás responsável pelo efeito estufa antropogênico na atmosfera terrestre?',
        'subject': 'Química',
        'topic': 'Química Ambiental',
        'difficulty': 1,
        'year': 2018,
        'exam_source': 'ENEM',
        'option_a': 'Oxigênio (O₂)',
        'option_b': 'Dióxido de Carbono (CO₂)',
        'option_c': 'Nitrogênio (N₂)',
        'option_d': 'Argônio (Ar)',
        'option_e': 'Hidrogênio (H₂)',
        'correct_option': 'B',
        'explanation':
            'O CO₂ é o principal gás de efeito estufa de origem humana, sendo emitido principalmente pela queima de combustíveis fósseis.',
        'image_path': null,
        'is_favorite': 0,
        'created_at': now,
      },
    ];

    final batch = db.batch();
    for (final q in seedQuestions) {
      batch.insert(DbConstants.tableQuestions, q,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // ══════════════════════════════════════════════════════════
  //  CRUD · USERS
  // ══════════════════════════════════════════════════════════

  /// Insere ou retorna o utilizador existente (app tem apenas 1 utilizador local)
  Future<int> insertUser(User user) async {
    final db = await database;
    final model = UserModel.fromEntity(user);
    return await db.insert(
      DbConstants.tableUsers,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser(int id) async {
    final db = await database;
    final maps = await db.query(
      DbConstants.tableUsers,
      where: '${DbConstants.colUserId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  /// Retorna o primeiro utilizador (perfil único local)
  Future<UserModel?> getFirstUser() async {
    final db = await database;
    final maps = await db.query(
      DbConstants.tableUsers,
      orderBy: '${DbConstants.colUserId} ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final model = UserModel.fromEntity(user);
    return await db.update(
      DbConstants.tableUsers,
      model.toMap(),
      where: '${DbConstants.colUserId} = ?',
      whereArgs: [user.id],
    );
  }

  /// Incrementa streak e totais directamente (evita race conditions)
  Future<void> recordCorrectAnswer(int userId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE ${DbConstants.tableUsers}
      SET
        ${DbConstants.colUserTotalAnswered} = ${DbConstants.colUserTotalAnswered} + 1,
        ${DbConstants.colUserTotalCorrect}  = ${DbConstants.colUserTotalCorrect}  + 1
      WHERE ${DbConstants.colUserId} = ?
    ''', [userId]);
  }

  Future<void> recordWrongAnswer(int userId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE ${DbConstants.tableUsers}
      SET ${DbConstants.colUserTotalAnswered} = ${DbConstants.colUserTotalAnswered} + 1
      WHERE ${DbConstants.colUserId} = ?
    ''', [userId]);
  }

  Future<void> updateStreak(int userId, int newStreak) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE ${DbConstants.tableUsers}
      SET
        ${DbConstants.colUserCurrentStreak} = ?,
        ${DbConstants.colUserMaxStreak} = MAX(${DbConstants.colUserMaxStreak}, ?)
      WHERE ${DbConstants.colUserId} = ?
    ''', [newStreak, newStreak, userId]);
  }

  // ══════════════════════════════════════════════════════════
  //  CRUD · QUESTIONS
  // ══════════════════════════════════════════════════════════

  Future<int> insertQuestion(Question question) async {
    final db = await database;
    final model = QuestionModel.fromEntity(question);
    return await db.insert(
      DbConstants.tableQuestions,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<QuestionModel>> getAllQuestions() async {
    final db = await database;
    final maps = await db.query(
      DbConstants.tableQuestions,
      orderBy: '${DbConstants.colQuestionCreatedAt} DESC',
    );
    return maps.map(QuestionModel.fromMap).toList();
  }

  /// Busca com filtros combinados (matéria, dificuldade, fonte, favoritos)
  Future<List<QuestionModel>> getFilteredQuestions({
    List<String>? subjects,
    List<int>? difficulties, // 1=Fácil, 2=Médio, 3=Difícil
    String? examSource,
    bool? favoritesOnly,
    String? searchText,
    int? limit,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (subjects != null && subjects.isNotEmpty) {
      final placeholders = List.filled(subjects.length, '?').join(',');
      whereClauses.add('${DbConstants.colQuestionSubject} IN ($placeholders)');
      whereArgs.addAll(subjects);
    }

    if (difficulties != null && difficulties.isNotEmpty) {
      final placeholders = List.filled(difficulties.length, '?').join(',');
      whereClauses.add('${DbConstants.colQuestionDifficulty} IN ($placeholders)');
      whereArgs.addAll(difficulties);
    }

    if (examSource != null && examSource.isNotEmpty) {
      whereClauses.add('${DbConstants.colQuestionExamSource} = ?');
      whereArgs.add(examSource);
    }

    if (favoritesOnly == true) {
      whereClauses.add('${DbConstants.colQuestionIsFavorite} = 1');
    }

    if (searchText != null && searchText.isNotEmpty) {
      whereClauses.add('${DbConstants.colQuestionText} LIKE ?');
      whereArgs.add('%$searchText%');
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      DbConstants.tableQuestions,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'RANDOM()',
      limit: limit,
    );

    return maps.map(QuestionModel.fromMap).toList();
  }

  /// Questões que o utilizador errou (para Revisão Inteligente)
  Future<List<QuestionModel>> getWrongQuestions(int userId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT q.*
      FROM ${DbConstants.tableQuestions} q
      INNER JOIN ${DbConstants.tableAttempts} a
        ON q.${DbConstants.colQuestionId} = a.${DbConstants.colAttemptQuestionId}
      WHERE a.${DbConstants.colAttemptUserId} = ?
        AND a.${DbConstants.colAttemptIsCorrect} = 0
      ORDER BY a.${DbConstants.colAttemptAnsweredAt} DESC
    ''', [userId]);
    return maps.map(QuestionModel.fromMap).toList();
  }

  /// Questões favoritas
  Future<List<QuestionModel>> getFavoriteQuestions() async {
    final db = await database;
    final maps = await db.query(
      DbConstants.tableQuestions,
      where: '${DbConstants.colQuestionIsFavorite} = 1',
      orderBy: '${DbConstants.colQuestionCreatedAt} DESC',
    );
    return maps.map(QuestionModel.fromMap).toList();
  }

  Future<int> toggleFavorite(int questionId, bool newValue) async {
    final db = await database;
    return await db.update(
      DbConstants.tableQuestions,
      {DbConstants.colQuestionIsFavorite: newValue ? 1 : 0},
      where: '${DbConstants.colQuestionId} = ?',
      whereArgs: [questionId],
    );
  }

  Future<int> getTotalQuestionsCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbConstants.tableQuestions}');
    return (result.first['count'] as int?) ?? 0;
  }

  // ══════════════════════════════════════════════════════════
  //  CRUD · ATTEMPTS
  // ══════════════════════════════════════════════════════════

  Future<int> insertAttempt(Attempt attempt) async {
    final db = await database;
    final model = AttemptModel.fromEntity(attempt);
    return await db.insert(
      DbConstants.tableAttempts,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AttemptModel>> getAttemptsByUser(int userId,
      {int? limit}) async {
    final db = await database;
    final maps = await db.query(
      DbConstants.tableAttempts,
      where: '${DbConstants.colAttemptUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DbConstants.colAttemptAnsweredAt} DESC',
      limit: limit,
    );
    return maps.map(AttemptModel.fromMap).toList();
  }

  Future<List<AttemptModel>> getAttemptsBySession(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      DbConstants.tableAttempts,
      where: '${DbConstants.colAttemptSessionId} = ?',
      whereArgs: [sessionId],
      orderBy: '${DbConstants.colAttemptAnsweredAt} ASC',
    );
    return maps.map(AttemptModel.fromMap).toList();
  }

  // ──────────────────────────────────────────────────────────
  //  ESTATÍSTICAS via SQL (Ecrã 7 + Widgets)
  // ──────────────────────────────────────────────────────────

  /// Taxa de acerto por matéria (para gráfico de radar)
  Future<Map<String, double>> getAccuracyBySubject(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        q.${DbConstants.colQuestionSubject}  AS subject,
        COUNT(*)                              AS total,
        SUM(a.${DbConstants.colAttemptIsCorrect}) AS correct
      FROM ${DbConstants.tableAttempts} a
      INNER JOIN ${DbConstants.tableQuestions} q
        ON a.${DbConstants.colAttemptQuestionId} = q.${DbConstants.colQuestionId}
      WHERE a.${DbConstants.colAttemptUserId} = ?
      GROUP BY q.${DbConstants.colQuestionSubject}
    ''', [userId]);

    final map = <String, double>{};
    for (final row in result) {
      final subject = row['subject'] as String;
      final total = (row['total'] as int?) ?? 0;
      final correct = (row['correct'] as int?) ?? 0;
      map[subject] = total == 0 ? 0.0 : correct / total;
    }
    return map;
  }

  /// Respostas por dia nos últimos 7 dias (evolução semanal)
  Future<List<Map<String, dynamic>>> getWeeklyProgress(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        DATE(${DbConstants.colAttemptAnsweredAt})           AS day,
        COUNT(*)                                             AS total,
        SUM(${DbConstants.colAttemptIsCorrect})             AS correct
      FROM ${DbConstants.tableAttempts}
      WHERE ${DbConstants.colAttemptUserId} = ?
        AND ${DbConstants.colAttemptAnsweredAt} >= DATE('now', '-6 days')
      GROUP BY DATE(${DbConstants.colAttemptAnsweredAt})
      ORDER BY day ASC
    ''', [userId]);
  }

  /// Locais com mais respostas corretas (cruzamento GPS) ⭐
  Future<List<Map<String, dynamic>>> getTopStudyLocations(int userId,
      {int limit = 5}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        ${DbConstants.colAttemptLocationName}           AS location,
        COUNT(*)                                         AS total,
        SUM(${DbConstants.colAttemptIsCorrect})         AS correct,
        AVG(CAST(${DbConstants.colAttemptIsCorrect} AS REAL)) AS accuracy
      FROM ${DbConstants.tableAttempts}
      WHERE ${DbConstants.colAttemptUserId} = ?
        AND ${DbConstants.colAttemptLocationName} IS NOT NULL
      GROUP BY ${DbConstants.colAttemptLocationName}
      ORDER BY accuracy DESC
      LIMIT ?
    ''', [userId, limit]);
  }

  /// Desafio do dia: retorna 1 questão não respondida hoje
  Future<QuestionModel?> getDailyChallenge(int userId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT q.* FROM ${DbConstants.tableQuestions} q
      WHERE q.${DbConstants.colQuestionId} NOT IN (
        SELECT a.${DbConstants.colAttemptQuestionId}
        FROM ${DbConstants.tableAttempts} a
        WHERE a.${DbConstants.colAttemptUserId} = ?
          AND DATE(a.${DbConstants.colAttemptAnsweredAt}) = DATE('now')
      )
      ORDER BY RANDOM()
      LIMIT 1
    ''', [userId]);

    if (maps.isEmpty) return null;
    return QuestionModel.fromMap(maps.first);
  }

  // ══════════════════════════════════════════════════════════
  //  CRUD · STUDY SESSIONS
  // ══════════════════════════════════════════════════════════

  Future<void> insertStudySession(StudySession session) async {
    final db = await database;
    final model = StudySessionModel.fromEntity(session);
    await db.insert(
      DbConstants.tableStudySessions,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudySessionModel>> getStudySessionsByUser(int userId,
      {int? limit}) async {
    final db = await database;
    final maps = await db.query(
      DbConstants.tableStudySessions,
      where: '${DbConstants.colSessionUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DbConstants.colSessionStartedAt} DESC',
      limit: limit,
    );
    return maps.map(StudySessionModel.fromMap).toList();
  }

  // ══════════════════════════════════════════════════════════
  //  UTILITÁRIOS
  // ══════════════════════════════════════════════════════════

  /// Fecha a conexão (utilizar em testes)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Apaga todos os dados do utilizador (reset de perfil)
  Future<void> clearUserData(int userId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        DbConstants.tableAttempts,
        where: '${DbConstants.colAttemptUserId} = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        DbConstants.tableStudySessions,
        where: '${DbConstants.colSessionUserId} = ?',
        whereArgs: [userId],
      );
      await txn.update(
        DbConstants.tableUsers,
        {
          DbConstants.colUserCurrentStreak: 0,
          DbConstants.colUserMaxStreak: 0,
          DbConstants.colUserTotalAnswered: 0,
          DbConstants.colUserTotalCorrect: 0,
        },
        where: '${DbConstants.colUserId} = ?',
        whereArgs: [userId],
      );
    });
  }

  /// Retorna o tamanho do banco em bytes (para debug/perfil)
  Future<int> getDatabaseSizeBytes() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.databaseName);
    try {
      final file = File(path);
      return await file.length();
    } catch (_) {
      return 0;
    }
  }
}
