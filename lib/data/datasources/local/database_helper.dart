// ============================================================
//  database_helper.dart
//  Gabarita · SQLite Database Helper (Singleton)
//  Tabelas: users · questions · attempts · study_sessions
// ============================================================

import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/db_constants.dart';
import '../../../domain/entities/entities.dart';
import '../../models/models.dart';

class QuestionUpsertResult {
  const QuestionUpsertResult({required this.inserted, required this.updated});

  final int inserted;
  final int updated;
}

class _SimuladoCandidate {
  const _SimuladoCandidate({
    required this.question,
    required this.year,
    required this.lastSelectedAt,
  });

  final QuestionModel question;
  final int year;
  final DateTime? lastSelectedAt;
}

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
    await _createTableUserStats(db);
    await _createTableStudySessions(db);
    await _createTableStudyProgress(db);
    await _createTableStudyPlaces(db);
    await _createTableSimuladoQuestionHistory(db);
    await _createIndexes(db);
    await _seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTableUserStats(db);
      await _createIndexes(db);
    }
    if (oldVersion < 3) {
      await _createTableStudyProgress(db);
    }
    if (oldVersion < 4) {
      await _createTableStudyPlaces(db);
    }
    if (oldVersion < 5) {
      await _createTableSimuladoQuestionHistory(db);
    }
    if (oldVersion < 6) {
      await _cleanQuestionBank(db);
    }
    await _createIndexes(db);
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
  Future<void> _createTableUserStats(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableUserStats} (
        ${DbConstants.colUserStatsId}             INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colUserStatsUserId}         INTEGER NOT NULL REFERENCES ${DbConstants.tableUsers}(id) ON DELETE CASCADE,
        ${DbConstants.colUserStatsCategory}       TEXT    NOT NULL,
        ${DbConstants.colUserStatsTotalAnswered}  INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colUserStatsTotalCorrect}   INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colUserStatsAccuracyRate}   REAL    NOT NULL DEFAULT 0,
        ${DbConstants.colUserStatsLastUpdatedAt}  TEXT    NOT NULL,
        UNIQUE(${DbConstants.colUserStatsUserId}, ${DbConstants.colUserStatsCategory})
      )
    ''');
  }

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

  Future<void> _createTableStudyProgress(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableStudyProgress} (
        ${DbConstants.colProgressUserId} INTEGER PRIMARY KEY REFERENCES ${DbConstants.tableUsers}(id) ON DELETE CASCADE,
        ${DbConstants.colProgressCurrentStreak} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colProgressMaxStreak} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colProgressWeeklyGoalQuestions} INTEGER NOT NULL DEFAULT 50,
        ${DbConstants.colProgressWeeklyAnsweredQuestions} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colProgressLastStudyDate} TEXT,
        ${DbConstants.colProgressWeekStartedAt} TEXT
      )
    ''');
  }

  Future<void> _createTableStudyPlaces(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableStudyPlaces} (
        ${DbConstants.colStudyPlaceId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colStudyPlaceName} TEXT NOT NULL,
        ${DbConstants.colStudyPlaceLatitude} REAL NOT NULL,
        ${DbConstants.colStudyPlaceLongitude} REAL NOT NULL,
        ${DbConstants.colStudyPlaceCreatedAt} TEXT NOT NULL,
        ${DbConstants.colStudyPlaceLastSeenAt} TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTableSimuladoQuestionHistory(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableSimuladoQuestionHistory} (
        ${DbConstants.colSimuladoHistoryQuestionId} INTEGER PRIMARY KEY REFERENCES ${DbConstants.tableQuestions}(id) ON DELETE CASCADE,
        ${DbConstants.colSimuladoHistoryLastSelectedAt} TEXT NOT NULL,
        ${DbConstants.colSimuladoHistorySelectionCount} INTEGER NOT NULL DEFAULT 0
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
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_questions_exam_year
        ON ${DbConstants.tableQuestions}(${DbConstants.colQuestionExamSource}, ${DbConstants.colQuestionYear})
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
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_user_stats_user_category
        ON ${DbConstants.tableUserStats}(${DbConstants.colUserStatsUserId}, ${DbConstants.colUserStatsCategory})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sessions_user_started_at
        ON ${DbConstants.tableStudySessions}(${DbConstants.colSessionUserId}, ${DbConstants.colSessionStartedAt})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_study_places_coordinates
        ON ${DbConstants.tableStudyPlaces}(${DbConstants.colStudyPlaceLatitude}, ${DbConstants.colStudyPlaceLongitude})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_simulado_history_last_selected
        ON ${DbConstants.tableSimuladoQuestionHistory}(${DbConstants.colSimuladoHistoryLastSelectedAt})
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
      batch.insert(
        DbConstants.tableQuestions,
        q,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
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

  // ══════════════════════════════════════════════════════════
  //  CRUD · QUESTIONS
  // ══════════════════════════════════════════════════════════

  Future<int> insertQuestion(Question question) async {
    final db = await database;
    final model = QuestionModel.fromEntity(question);
    return await db.insert(
      DbConstants.tableQuestions,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
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
      whereClauses.add(
        '${DbConstants.colQuestionDifficulty} IN ($placeholders)',
      );
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
      whereClauses.add('''
        (
          ${DbConstants.colQuestionText} LIKE ?
          OR ${DbConstants.colQuestionTopic} LIKE ?
          OR ${DbConstants.colQuestionSubject} LIKE ?
          OR ${DbConstants.colQuestionExamSource} LIKE ?
        )
      ''');
      final pattern = '%$searchText%';
      whereArgs.addAll([pattern, pattern, pattern, pattern]);
    }

    final whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      DbConstants.tableQuestions,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy:
          '${DbConstants.colQuestionCreatedAt} DESC, ${DbConstants.colQuestionId} DESC',
      limit: limit,
    );

    return maps.map(QuestionModel.fromMap).toList();
  }

  Future<List<QuestionModel>> getBalancedSimuladoQuestions({
    required int quantity,
    List<String>? subjects,
    String? examSource,
  }) async {
    if (quantity <= 0) return const <QuestionModel>[];

    final db = await database;
    final whereClauses = <String>[
      'q.${DbConstants.colQuestionYear} IS NOT NULL',
      "q.${DbConstants.colQuestionExamSource} LIKE 'ENEM %'",
      "(q.${DbConstants.colQuestionImagePath} IS NULL OR TRIM(q.${DbConstants.colQuestionImagePath}) = '')",
      "TRIM(q.${DbConstants.colQuestionText}) <> ''",
      "TRIM(q.${DbConstants.colQuestionSubject}) <> ''",
      "TRIM(q.${DbConstants.colQuestionTopic}) <> ''",
      "TRIM(q.${DbConstants.colQuestionOptionA}) <> ''",
      "TRIM(q.${DbConstants.colQuestionOptionB}) <> ''",
      "TRIM(q.${DbConstants.colQuestionOptionC}) <> ''",
      "TRIM(q.${DbConstants.colQuestionOptionD}) <> ''",
      "TRIM(COALESCE(q.${DbConstants.colQuestionOptionE}, '')) <> ''",
      "q.${DbConstants.colQuestionCorrectOption} IN ('A', 'B', 'C', 'D', 'E')",
    ];
    final whereArgs = <Object?>[];

    if (subjects != null && subjects.isNotEmpty) {
      final placeholders = List.filled(subjects.length, '?').join(',');
      whereClauses.add(
        'q.${DbConstants.colQuestionSubject} IN ($placeholders)',
      );
      whereArgs.addAll(subjects);
    }

    if (examSource != null && examSource.trim().isNotEmpty) {
      whereClauses.add('q.${DbConstants.colQuestionExamSource} = ?');
      whereArgs.add(examSource.trim());
    }

    final rows = await db.rawQuery(
      '''
        SELECT q.*, h.${DbConstants.colSimuladoHistoryLastSelectedAt}
        FROM ${DbConstants.tableQuestions} q
        LEFT JOIN ${DbConstants.tableSimuladoQuestionHistory} h
          ON h.${DbConstants.colSimuladoHistoryQuestionId} = q.${DbConstants.colQuestionId}
        WHERE ${whereClauses.join(' AND ')}
        ORDER BY RANDOM()
      ''',
      whereArgs,
    );
    final candidates = rows
        .map(
          (row) => _SimuladoCandidate(
            question: QuestionModel.fromMap(row),
            year: _asInt(row[DbConstants.colQuestionYear]) ?? 0,
            lastSelectedAt: DateTime.tryParse(
              row[DbConstants.colSimuladoHistoryLastSelectedAt]?.toString() ??
                  '',
            ),
          ),
        )
        .where((candidate) => candidate.year > 0)
        .toList(growable: false);

    final unseen = candidates
        .where((candidate) => candidate.lastSelectedAt == null)
        .toList(growable: false);
    final seen = candidates
        .where((candidate) => candidate.lastSelectedAt != null)
        .toList(growable: false)
      ..sort(
        (first, second) =>
            first.lastSelectedAt!.compareTo(second.lastSelectedAt!),
      );

    final selected = <_SimuladoCandidate>[
      ..._takeBalancedQuestions(unseen, quantity),
    ];
    if (selected.length < quantity) {
      selected.addAll(
        _takeBalancedQuestions(seen, quantity - selected.length),
      );
    }

    await _recordSimuladoSelection(
      selected
          .map((candidate) => candidate.question.id)
          .whereType<int>()
          .toList(growable: false),
    );
    return selected.map((candidate) => candidate.question).toList();
  }

  List<_SimuladoCandidate> _takeBalancedQuestions(
    List<_SimuladoCandidate> candidates,
    int quantity,
  ) {
    if (quantity <= 0 || candidates.isEmpty) {
      return const <_SimuladoCandidate>[];
    }

    final questionsByYear = <int, List<_SimuladoCandidate>>{};
    for (final candidate in candidates) {
      questionsByYear.putIfAbsent(candidate.year, () => []).add(candidate);
    }

    final years = questionsByYear.keys.toList()..shuffle(math.Random.secure());
    final selected = <_SimuladoCandidate>[];

    while (selected.length < quantity && years.isNotEmpty) {
      var selectedInRound = false;
      for (final year in years) {
        final questions = questionsByYear[year]!;
        if (questions.isEmpty) continue;

        selected.add(questions.removeAt(0));
        selectedInRound = true;
        if (selected.length == quantity) break;
      }
      years.removeWhere((year) => questionsByYear[year]!.isEmpty);
      if (!selectedInRound) break;
    }

    return selected;
  }

  Future<void> _recordSimuladoSelection(List<int> questionIds) async {
    if (questionIds.isEmpty) return;

    final db = await database;
    final selectedAt = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      for (final questionId in questionIds) {
        final updated = await txn.rawUpdate(
          '''
            UPDATE ${DbConstants.tableSimuladoQuestionHistory}
            SET ${DbConstants.colSimuladoHistoryLastSelectedAt} = ?,
                ${DbConstants.colSimuladoHistorySelectionCount} = ${DbConstants.colSimuladoHistorySelectionCount} + 1
            WHERE ${DbConstants.colSimuladoHistoryQuestionId} = ?
          ''',
          [selectedAt, questionId],
        );
        if (updated > 0) continue;

        await txn.insert(DbConstants.tableSimuladoQuestionHistory, {
          DbConstants.colSimuladoHistoryQuestionId: questionId,
          DbConstants.colSimuladoHistoryLastSelectedAt: selectedAt,
          DbConstants.colSimuladoHistorySelectionCount: 1,
        });
      }
    });
  }

  /// Questões que o utilizador errou (para Revisão Inteligente)
  Future<List<QuestionModel>> getWrongQuestions(int userId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT DISTINCT q.*
      FROM ${DbConstants.tableQuestions} q
      INNER JOIN ${DbConstants.tableAttempts} a
        ON q.${DbConstants.colQuestionId} = a.${DbConstants.colAttemptQuestionId}
      WHERE a.${DbConstants.colAttemptUserId} = ?
        AND a.${DbConstants.colAttemptIsCorrect} = 0
      ORDER BY a.${DbConstants.colAttemptAnsweredAt} DESC
    ''',
      [userId],
    );
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
      'SELECT COUNT(*) as count FROM ${DbConstants.tableQuestions}',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getQuestionsCountByExamSource(String examSource) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM ${DbConstants.tableQuestions}
      WHERE ${DbConstants.colQuestionExamSource} = ?
      ''',
      [examSource],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ══════════════════════════════════════════════════════════
  //  CRUD · ATTEMPTS
  // ══════════════════════════════════════════════════════════

  Future<int> insertAttempt(Attempt attempt) async {
    final db = await database;
    final model = AttemptModel.fromEntity(attempt);
    return await db.transaction((txn) async {
      final attemptId = await txn.insert(
        DbConstants.tableAttempts,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      final progress = await _recordAnsweredQuestionInTransaction(
        txn,
        userId: attempt.userId,
        answeredAt: attempt.answeredAt,
      );
      await txn.rawUpdate(
        '''
        UPDATE ${DbConstants.tableUsers}
        SET
          ${DbConstants.colUserTotalAnswered} = ${DbConstants.colUserTotalAnswered} + 1,
          ${DbConstants.colUserTotalCorrect} = ${DbConstants.colUserTotalCorrect} + ?,
          ${DbConstants.colUserCurrentStreak} = ?,
          ${DbConstants.colUserMaxStreak} = ?
        WHERE ${DbConstants.colUserId} = ?
      ''',
        [
          attempt.isCorrect ? 1 : 0,
          progress.currentStreak,
          progress.maxStreak,
          attempt.userId,
        ],
      );
      await _upsertUserStatsForAttempt(txn, attempt);
      return attemptId;
    });
  }

  Future<List<AttemptModel>> getAttemptsByUser(int userId, {int? limit}) async {
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
    final result = await db.rawQuery(
      '''
      SELECT
        q.${DbConstants.colQuestionSubject}  AS subject,
        COUNT(*)                              AS total,
        SUM(a.${DbConstants.colAttemptIsCorrect}) AS correct
      FROM ${DbConstants.tableAttempts} a
      INNER JOIN ${DbConstants.tableQuestions} q
        ON a.${DbConstants.colAttemptQuestionId} = q.${DbConstants.colQuestionId}
      WHERE a.${DbConstants.colAttemptUserId} = ?
      GROUP BY q.${DbConstants.colQuestionSubject}
    ''',
      [userId],
    );

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
    return await db.rawQuery(
      '''
      SELECT
        DATE(${DbConstants.colAttemptAnsweredAt})           AS day,
        COUNT(*)                                             AS total,
        SUM(${DbConstants.colAttemptIsCorrect})             AS correct
      FROM ${DbConstants.tableAttempts}
      WHERE ${DbConstants.colAttemptUserId} = ?
        AND ${DbConstants.colAttemptAnsweredAt} >= DATE('now', '-6 days')
      GROUP BY DATE(${DbConstants.colAttemptAnsweredAt})
      ORDER BY day ASC
    ''',
      [userId],
    );
  }

  /// Locais com mais respostas corretas (cruzamento GPS) ⭐
  Future<List<Map<String, dynamic>>> getTopStudyLocations(
    int userId, {
    int limit = 5,
  }) async {
    final db = await database;
    return await db.rawQuery(
      '''
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
    ''',
      [userId, limit],
    );
  }

  /// Desafio do dia: retorna 1 questão não respondida hoje
  Future<QuestionModel?> getDailyChallenge(int userId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT q.* FROM ${DbConstants.tableQuestions} q
      WHERE q.${DbConstants.colQuestionId} NOT IN (
        SELECT a.${DbConstants.colAttemptQuestionId}
        FROM ${DbConstants.tableAttempts} a
        WHERE a.${DbConstants.colAttemptUserId} = ?
          AND DATE(a.${DbConstants.colAttemptAnsweredAt}) = DATE('now')
      )
      ORDER BY RANDOM()
      LIMIT 1
    ''',
      [userId],
    );

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

  Future<StudyProgress> getStudyProgress(int userId) async {
    final db = await database;
    final rows = await db.query(
      DbConstants.tableStudyProgress,
      where: '${DbConstants.colProgressUserId} = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return StudyProgress.initial();

    final current = _studyProgressFromMap(rows.first);
    final normalized = _resetProgressWeekIfNeeded(current, DateTime.now());
    if (normalized.weekStartedAt != current.weekStartedAt ||
        normalized.weeklyAnsweredQuestions != current.weeklyAnsweredQuestions) {
      await db.transaction(
        (txn) => _writeStudyProgress(txn, userId, normalized),
      );
    }
    return normalized;
  }

  Future<StudyProgress> recordAnsweredQuestion({
    required int userId,
    DateTime? answeredAt,
  }) async {
    final db = await database;
    return db.transaction(
      (txn) => _recordAnsweredQuestionInTransaction(
        txn,
        userId: userId,
        answeredAt: answeredAt ?? DateTime.now(),
      ),
    );
  }

  Future<StudyProgress> setWeeklyGoalQuestions({
    required int userId,
    required int value,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final current = await _readStudyProgress(txn, userId);
      final next = _resetProgressWeekIfNeeded(
        current,
        DateTime.now(),
      ).copyWith(weeklyGoalQuestions: value.clamp(1, 999).toInt());
      await _writeStudyProgress(txn, userId, next);
      return next;
    });
  }

  Future<void> clearStudyProgress(int userId) async {
    final db = await database;
    await db.delete(
      DbConstants.tableStudyProgress,
      where: '${DbConstants.colProgressUserId} = ?',
      whereArgs: [userId],
    );
  }

  Future<String> resolveStudyPlaceName({
    required double latitude,
    required double longitude,
    required double clusterRadiusMeters,
    required List<String> defaultNames,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final places = await txn.query(
        DbConstants.tableStudyPlaces,
        orderBy: '${DbConstants.colStudyPlaceLastSeenAt} DESC',
      );
      final now = DateTime.now();

      for (final place in places) {
        final distance = _distanceMeters(
          _asDouble(place[DbConstants.colStudyPlaceLatitude]),
          _asDouble(place[DbConstants.colStudyPlaceLongitude]),
          latitude,
          longitude,
        );
        if (distance > clusterRadiusMeters) continue;

        await txn.update(
          DbConstants.tableStudyPlaces,
          {DbConstants.colStudyPlaceLastSeenAt: now.toIso8601String()},
          where: '${DbConstants.colStudyPlaceId} = ?',
          whereArgs: [place[DbConstants.colStudyPlaceId]],
        );
        return place[DbConstants.colStudyPlaceName]?.toString() ?? 'Local';
      }

      final index = places.length;
      final name = index < defaultNames.length
          ? defaultNames[index]
          : 'Local ${index + 1}';
      await txn.insert(DbConstants.tableStudyPlaces, {
        DbConstants.colStudyPlaceName: name,
        DbConstants.colStudyPlaceLatitude: latitude,
        DbConstants.colStudyPlaceLongitude: longitude,
        DbConstants.colStudyPlaceCreatedAt: now.toIso8601String(),
        DbConstants.colStudyPlaceLastSeenAt: now.toIso8601String(),
      });
      return name;
    });
  }

  Future<QuestionModel?> getQuestionBySourceAndTopic({
    required String examSource,
    required String topic,
  }) async {
    final db = await database;
    final maps = await db.query(
      DbConstants.tableQuestions,
      where:
          '${DbConstants.colQuestionExamSource} = ? AND ${DbConstants.colQuestionTopic} = ?',
      whereArgs: [examSource, topic],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return QuestionModel.fromMap(maps.first);
  }

  Future<int> upsertQuestionBySourceAndTopic(Question question) async {
    await upsertQuestionsBySourceAndTopic([question]);
    final stored = await getQuestionBySourceAndTopic(
      examSource: question.examSource ?? '',
      topic: question.topic,
    );
    return stored?.id ?? 0;
  }

  Future<QuestionUpsertResult> upsertQuestionsBySourceAndTopic(
    List<Question> questions,
  ) async {
    if (questions.isEmpty) {
      return const QuestionUpsertResult(inserted: 0, updated: 0);
    }

    final db = await database;
    return db.transaction((txn) => _upsertQuestions(txn, questions));
  }

  Future<QuestionUpsertResult> replaceQuestionsFromSource({
    required String examSource,
    required List<Question> questions,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final result = await _upsertQuestions(txn, questions);
      final topics = questions.map((question) => question.topic).toSet();

      if (topics.isEmpty) {
        await txn.delete(
          DbConstants.tableQuestions,
          where: '${DbConstants.colQuestionExamSource} = ?',
          whereArgs: [examSource],
        );
        return result;
      }

      final placeholders = List.filled(topics.length, '?').join(',');
      await txn.delete(
        DbConstants.tableQuestions,
        where:
            '${DbConstants.colQuestionExamSource} = ? AND ${DbConstants.colQuestionTopic} NOT IN ($placeholders)',
        whereArgs: [examSource, ...topics],
      );
      return result;
    });
  }

  Future<QuestionUpsertResult> _upsertQuestions(
    Transaction txn,
    List<Question> questions,
  ) async {
    var inserted = 0;
    var updated = 0;

    for (final question in questions) {
      final existing = await txn.query(
        DbConstants.tableQuestions,
        columns: [
          DbConstants.colQuestionId,
          DbConstants.colQuestionIsFavorite,
          DbConstants.colQuestionCreatedAt,
        ],
        where:
            '${DbConstants.colQuestionExamSource} = ? AND ${DbConstants.colQuestionTopic} = ?',
        whereArgs: [question.examSource ?? '', question.topic],
        limit: 1,
      );

      if (existing.isEmpty) {
        await txn.insert(
          DbConstants.tableQuestions,
          QuestionModel.fromEntity(question).toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        inserted++;
        continue;
      }

      final stored = existing.first;
      final model = QuestionModel.fromEntity(
        question.copyWith(
          id: stored[DbConstants.colQuestionId] as int?,
          isFavorite:
              (stored[DbConstants.colQuestionIsFavorite] as int? ?? 0) != 0,
          createdAt: DateTime.tryParse(
                stored[DbConstants.colQuestionCreatedAt]?.toString() ?? '',
              ) ??
              question.createdAt,
        ),
      );
      await txn.update(
        DbConstants.tableQuestions,
        model.toMap(),
        where: '${DbConstants.colQuestionId} = ?',
        whereArgs: [stored[DbConstants.colQuestionId]],
      );
      updated++;
    }

    return QuestionUpsertResult(inserted: inserted, updated: updated);
  }

  Future<List<StudySessionModel>> getStudySessionsByUser(
    int userId, {
    int? limit,
  }) async {
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

  Future<void> _cleanQuestionBank(Database db) async {
    await db.delete(
      DbConstants.tableQuestions,
      where: '''
        TRIM(${DbConstants.colQuestionText}) = ''
        OR TRIM(${DbConstants.colQuestionSubject}) = ''
        OR TRIM(${DbConstants.colQuestionTopic}) = ''
        OR TRIM(${DbConstants.colQuestionOptionA}) = ''
        OR TRIM(${DbConstants.colQuestionOptionB}) = ''
        OR TRIM(${DbConstants.colQuestionOptionC}) = ''
        OR TRIM(${DbConstants.colQuestionOptionD}) = ''
        OR TRIM(COALESCE(${DbConstants.colQuestionOptionE}, '')) = ''
        OR ${DbConstants.colQuestionCorrectOption} NOT IN ('A', 'B', 'C', 'D', 'E')
        OR (
          ${DbConstants.colQuestionExamSource} LIKE 'ENEM %'
          AND TRIM(COALESCE(${DbConstants.colQuestionImagePath}, '')) <> ''
        )
      ''',
    );
    await _removeDuplicateQuestionRecords(db);
  }

  Future<void> _removeDuplicateQuestionRecords(Database db) async {
    final rows = await db.query(
      DbConstants.tableQuestions,
      columns: [
        DbConstants.colQuestionId,
        DbConstants.colQuestionExamSource,
        DbConstants.colQuestionYear,
        DbConstants.colQuestionText,
        DbConstants.colQuestionOptionA,
        DbConstants.colQuestionOptionB,
        DbConstants.colQuestionOptionC,
        DbConstants.colQuestionOptionD,
        DbConstants.colQuestionOptionE,
        DbConstants.colQuestionCorrectOption,
        DbConstants.colQuestionIsFavorite,
      ],
      orderBy: '${DbConstants.colQuestionId} ASC',
    );
    final firstQuestionByContent = <String, Map<String, Object?>>{};

    for (final row in rows) {
      final contentKey = _questionContentKey(row);
      final original = firstQuestionByContent[contentKey];
      if (original == null) {
        firstQuestionByContent[contentKey] = row;
        continue;
      }

      final originalId = _asInt(original[DbConstants.colQuestionId]);
      final duplicateId = _asInt(row[DbConstants.colQuestionId]);
      if (originalId == null || duplicateId == null) continue;

      if ((row[DbConstants.colQuestionIsFavorite] as int? ?? 0) != 0) {
        await db.update(
          DbConstants.tableQuestions,
          {DbConstants.colQuestionIsFavorite: 1},
          where: '${DbConstants.colQuestionId} = ?',
          whereArgs: [originalId],
        );
      }
      await db.update(
        DbConstants.tableAttempts,
        {DbConstants.colAttemptQuestionId: originalId},
        where: '${DbConstants.colAttemptQuestionId} = ?',
        whereArgs: [duplicateId],
      );
      await db.delete(
        DbConstants.tableSimuladoQuestionHistory,
        where: '${DbConstants.colSimuladoHistoryQuestionId} = ?',
        whereArgs: [duplicateId],
      );
      await db.delete(
        DbConstants.tableQuestions,
        where: '${DbConstants.colQuestionId} = ?',
        whereArgs: [duplicateId],
      );
    }
  }

  String _questionContentKey(Map<String, Object?> row) {
    final fields = <String>[
      DbConstants.colQuestionExamSource,
      DbConstants.colQuestionYear,
      DbConstants.colQuestionText,
      DbConstants.colQuestionOptionA,
      DbConstants.colQuestionOptionB,
      DbConstants.colQuestionOptionC,
      DbConstants.colQuestionOptionD,
      DbConstants.colQuestionOptionE,
      DbConstants.colQuestionCorrectOption,
    ];
    return fields
        .map((field) => _normalizeQuestionContent(row[field]?.toString() ?? ''))
        .join('|');
  }

  String _normalizeQuestionContent(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
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
      await txn.delete(
        DbConstants.tableUserStats,
        where: '${DbConstants.colUserStatsUserId} = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        DbConstants.tableStudyProgress,
        where: '${DbConstants.colProgressUserId} = ?',
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

  Future<int> getTodayAnsweredCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DbConstants.tableAttempts}
      WHERE ${DbConstants.colAttemptUserId} = ?
        AND DATE(${DbConstants.colAttemptAnsweredAt}) = DATE('now')
    ''',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Map<String, dynamic>?> getLastStudiedTopic(int userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        q.${DbConstants.colQuestionTopic} AS topic,
        q.${DbConstants.colQuestionSubject} AS subject,
        q.${DbConstants.colQuestionExamSource} AS exam_source,
        a.${DbConstants.colAttemptAnsweredAt} AS answered_at
      FROM ${DbConstants.tableAttempts} a
      INNER JOIN ${DbConstants.tableQuestions} q
        ON a.${DbConstants.colAttemptQuestionId} = q.${DbConstants.colQuestionId}
      WHERE a.${DbConstants.colAttemptUserId} = ?
      ORDER BY a.${DbConstants.colAttemptAnsweredAt} DESC
      LIMIT 1
    ''',
      [userId],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<int>> getWeeklyAccuracyPercentages(int userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        DATE(${DbConstants.colAttemptAnsweredAt}) AS day,
        COUNT(*) AS total,
        SUM(${DbConstants.colAttemptIsCorrect}) AS correct
      FROM ${DbConstants.tableAttempts}
      WHERE ${DbConstants.colAttemptUserId} = ?
        AND ${DbConstants.colAttemptAnsweredAt} >= DATE('now', '-6 days')
      GROUP BY DATE(${DbConstants.colAttemptAnsweredAt})
    ''',
      [userId],
    );

    final byDay = <String, int>{};
    for (final row in rows) {
      final total = (row['total'] as int?) ?? 0;
      final correct = (row['correct'] as int?) ?? 0;
      final day = row['day']?.toString();
      if (day == null || total == 0) continue;
      byDay[day] = ((correct / total) * 100).round();
    }

    final now = DateTime.now();
    return List<int>.generate(7, (index) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
      final key = date.toIso8601String().split('T').first;
      return byDay[key] ?? 0;
    });
  }

  Future<Map<String, dynamic>?> getBestStudyLocationComparison(
    int userId,
  ) async {
    final locations = await getTopStudyLocations(userId, limit: 2);
    if (locations.isEmpty) return null;
    if (locations.length == 1) return locations.first;

    final best = locations.first;
    final second = locations[1];
    final bestAccuracy = _asDouble(best['accuracy']);
    final secondAccuracy = _asDouble(second['accuracy']);
    return <String, dynamic>{
      ...best,
      'comparison_location': second['location'],
      'comparison_delta': bestAccuracy - secondAccuracy,
    };
  }

  Future<StudyProgress> _readStudyProgress(Transaction txn, int userId) async {
    final rows = await txn.query(
      DbConstants.tableStudyProgress,
      where: '${DbConstants.colProgressUserId} = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty
        ? StudyProgress.initial()
        : _studyProgressFromMap(rows.first);
  }

  Future<StudyProgress> _recordAnsweredQuestionInTransaction(
    Transaction txn, {
    required int userId,
    required DateTime answeredAt,
  }) async {
    final current = _resetProgressWeekIfNeeded(
      await _readStudyProgress(txn, userId),
      answeredAt,
    );
    final previousStudyDay = current.lastStudyDate;
    final alreadyStudiedToday =
        previousStudyDay != null && _isSameDate(previousStudyDay, answeredAt);
    final nextStreak = alreadyStudiedToday
        ? current.currentStreak
        : _isYesterday(previousStudyDay, answeredAt)
            ? current.currentStreak + 1
            : 1;
    final next = current.copyWith(
      currentStreak: nextStreak,
      maxStreak: math.max(current.maxStreak, nextStreak),
      weeklyAnsweredQuestions: current.weeklyAnsweredQuestions + 1,
      lastStudyDate: answeredAt,
      weekStartedAt: _startOfWeek(answeredAt),
    );
    await _writeStudyProgress(txn, userId, next);
    return next;
  }

  Future<void> _writeStudyProgress(
    Transaction txn,
    int userId,
    StudyProgress progress,
  ) async {
    await txn.insert(
        DbConstants.tableStudyProgress,
        {
          DbConstants.colProgressUserId: userId,
          DbConstants.colProgressCurrentStreak: progress.currentStreak,
          DbConstants.colProgressMaxStreak: progress.maxStreak,
          DbConstants.colProgressWeeklyGoalQuestions:
              progress.weeklyGoalQuestions,
          DbConstants.colProgressWeeklyAnsweredQuestions:
              progress.weeklyAnsweredQuestions,
          DbConstants.colProgressLastStudyDate:
              progress.lastStudyDate?.toIso8601String(),
          DbConstants.colProgressWeekStartedAt:
              progress.weekStartedAt?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  StudyProgress _studyProgressFromMap(Map<String, Object?> map) {
    return StudyProgress(
      currentStreak: _asInt(map[DbConstants.colProgressCurrentStreak]) ?? 0,
      maxStreak: _asInt(map[DbConstants.colProgressMaxStreak]) ?? 0,
      weeklyGoalQuestions:
          _asInt(map[DbConstants.colProgressWeeklyGoalQuestions]) ?? 50,
      weeklyAnsweredQuestions:
          _asInt(map[DbConstants.colProgressWeeklyAnsweredQuestions]) ?? 0,
      lastStudyDate: DateTime.tryParse(
        map[DbConstants.colProgressLastStudyDate]?.toString() ?? '',
      ),
      weekStartedAt: DateTime.tryParse(
        map[DbConstants.colProgressWeekStartedAt]?.toString() ?? '',
      ),
    );
  }

  StudyProgress _resetProgressWeekIfNeeded(
    StudyProgress progress,
    DateTime now,
  ) {
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

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isYesterday(DateTime? previous, DateTime now) {
    if (previous == null) return false;
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    return _isSameDate(previous, yesterday);
  }

  double _distanceMeters(
    double firstLatitude,
    double firstLongitude,
    double secondLatitude,
    double secondLongitude,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _degreesToRadians(secondLatitude - firstLatitude);
    final longitudeDelta = _degreesToRadians(secondLongitude - firstLongitude);
    final a = math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(_degreesToRadians(firstLatitude)) *
            math.cos(_degreesToRadians(secondLatitude)) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _degreesToRadians(double value) => value * math.pi / 180;

  Future<void> _upsertUserStatsForAttempt(
    Transaction txn,
    Attempt attempt,
  ) async {
    final questionRows = await txn.query(
      DbConstants.tableQuestions,
      columns: [DbConstants.colQuestionSubject],
      where: '${DbConstants.colQuestionId} = ?',
      whereArgs: [attempt.questionId],
      limit: 1,
    );
    if (questionRows.isEmpty) return;

    final category =
        (questionRows.first[DbConstants.colQuestionSubject] as String?) ??
            'Geral';
    final now = DateTime.now().toIso8601String();

    final existingRows = await txn.query(
      DbConstants.tableUserStats,
      where:
          '${DbConstants.colUserStatsUserId} = ? AND ${DbConstants.colUserStatsCategory} = ?',
      whereArgs: [attempt.userId, category],
      limit: 1,
    );

    final correctIncrement = attempt.isCorrect ? 1 : 0;
    if (existingRows.isEmpty) {
      await txn.insert(DbConstants.tableUserStats, {
        DbConstants.colUserStatsUserId: attempt.userId,
        DbConstants.colUserStatsCategory: category,
        DbConstants.colUserStatsTotalAnswered: 1,
        DbConstants.colUserStatsTotalCorrect: correctIncrement,
        DbConstants.colUserStatsAccuracyRate: attempt.isCorrect ? 1.0 : 0.0,
        DbConstants.colUserStatsLastUpdatedAt: now,
      });
      return;
    }

    final existing = existingRows.first;
    final totalAnswered =
        ((existing[DbConstants.colUserStatsTotalAnswered] as int?) ?? 0) + 1;
    final totalCorrect =
        ((existing[DbConstants.colUserStatsTotalCorrect] as int?) ?? 0) +
            correctIncrement;

    await txn.update(
      DbConstants.tableUserStats,
      {
        DbConstants.colUserStatsTotalAnswered: totalAnswered,
        DbConstants.colUserStatsTotalCorrect: totalCorrect,
        DbConstants.colUserStatsAccuracyRate:
            totalAnswered == 0 ? 0.0 : totalCorrect / totalAnswered,
        DbConstants.colUserStatsLastUpdatedAt: now,
      },
      where:
          '${DbConstants.colUserStatsUserId} = ? AND ${DbConstants.colUserStatsCategory} = ?',
      whereArgs: [attempt.userId, category],
    );
  }

  double _asDouble(Object? value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
