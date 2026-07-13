// ============================================================
//  database_helper.dart
//  Gabarita · SQLite Database Helper (Singleton)
//  Tabelas: users · questions · attempts · study_sessions
// ============================================================

import 'dart:math' as math;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/db_constants.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/services/question_quality_policy.dart';
import '../../models/models.dart';
import 'local_file_size_stub.dart'
    if (dart.library.io) 'local_file_size_io.dart';

// Bloco DB-0.1 - resultado de uma operacao de upsert de questoes.
// "Upsert" significa: se a questao nao existe, insere; se ja existe, atualiza.
// Esse objeto volta com dois contadores para o repositorio saber o que mudou.
class QuestionUpsertResult {
  const QuestionUpsertResult({required this.inserted, required this.updated});

  // Quantas questoes novas foram criadas no banco.
  final int inserted;

  // Quantas questoes antigas foram atualizadas.
  final int updated;
}

// Bloco DB-0.2 - estrutura auxiliar usada para escolher questoes de simulado.
// Ela junta a questao em si com informacoes que ajudam a nao repetir sempre
// o mesmo ano e a mesma questao.
class _SimuladoCandidate {
  const _SimuladoCandidate({
    required this.question,
    required this.year,
    required this.lastSelectedAt,
  });

  // Questao que pode entrar no simulado.
  final QuestionModel question;

  // Ano do ENEM da questao. Usado para balancear a selecao entre anos.
  final int year;

  // Ultima vez que essa questao apareceu em um simulado.
  // Null significa que ela nunca foi usada, entao recebe prioridade.
  final DateTime? lastSelectedAt;
}

class DatabaseHelper {
  // Bloco 1 - construtor privado para aplicar Singleton.
  // Isso impede que outras partes do app criem varias conexoes de banco.
  DatabaseHelper._privateConstructor();

  // Bloco 2 - instancia unica usada no app inteiro.
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Bloco 3 - conexao SQLite em cache.
  // Depois de aberto, o banco fica guardado aqui para reutilizacao.
  static Database? _database;

  // ── Abertura / criação do banco ───────────────────────────
  Future<Database> get database async {
    // Bloco 4 - se ja abriu o banco antes, devolve a mesma conexao.
    if (_database != null) return _database!;

    // Bloco 5 - se ainda nao abriu, inicializa agora.
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Bloco 6 - pasta padrao do SQLite no dispositivo.
    final dbPath = await getDatabasesPath();

    // Bloco 7 - caminho completo do arquivo do banco.
    final path = join(dbPath, DbConstants.databaseName);

    // Bloco 8 - abre/cria o banco e informa callbacks de criacao/migracao.
    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Bloco 9 - ativa chaves estrangeiras no SQLite.
        // Ajuda a manter relacoes entre tabelas consistentes.
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  //  CRIAÇÃO DAS TABELAS

  Future<void> _onCreate(Database db, int version) async {
    // Bloco 10 - cria todas as tabelas quando o banco nasce do zero.
    // Bloco 10.1 - tabela do perfil do usuario.
    await _createTableUsers(db);
    // Bloco 10.2 - tabela principal das questoes.
    await _createTableQuestions(db);
    // Bloco 10.3 - tabela de tentativas/respostas.
    await _createTableAttempts(db);
    // Bloco 10.4 - tabela de estatisticas agregadas.
    await _createTableUserStats(db);
    // Bloco 10.5 - tabela de simulados finalizados.
    await _createTableStudySessions(db);
    // Bloco 10.6 - tabela de streak e meta semanal.
    await _createTableStudyProgress(db);
    // Bloco 10.7 - tabela de locais de estudo.
    await _createTableStudyPlaces(db);
    // Bloco 10.8 - tabela para evitar repetir questoes em simulados.
    await _createTableSimuladoQuestionHistory(db);
    // Bloco 10.9 - tabela normalizada de alternativas.
    await _createTableQuestionAlternatives(db);
    // Bloco 10.10 - tabela de favoritas.
    await _createTableFavoriteQuestions(db);
    // Bloco 10.11 - tabela de configuracoes simples.
    await _createTableAppSettings(db);
    // Bloco 10.12 - indices para acelerar consultas.
    await _createIndexes(db);
    // Bloco 10.13 - cria usuario/dados iniciais.
    await _seedInitialData(db);
    // Bloco 10.14 - preenche tabelas derivadas de questoes existentes.
    await _syncNormalizedQuestionTables(db);
  }

  // Bloco 11 - atualiza estrutura quando aumenta a versao do banco.
  // Cada if representa uma migracao incremental.
  //Quando a versão do banco aumenta chama _onUpgrade.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      //Se o banco ainda não recebeu as alterações da versão 2
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
    if (oldVersion < 7) {
      await _cleanQuestionBank(db);
    }
    if (oldVersion < 8) {
      await _createTableQuestionAlternatives(db);
      await _createTableFavoriteQuestions(db);
      await _createTableAppSettings(db);
      await _syncNormalizedQuestionTables(db);
    }
    await _createIndexes(db);
  }

  //  DDL · Tabela: users

  // Bloco DB-1 - cria a tabela de usuario/perfil.
  // Guarda dados visuais (nome/avatar) e numeros rapidos para gamificacao.
  // Esses totais ficam no usuario para a Home e o Perfil carregarem sem query pesada.
  Future<void> _createTableUsers(Database db) async {
    // Detalhe:
    // - avatar e TEXT porque pode ser null, caminho antigo ou data URI base64.
    // - current_streak/max_streak ficam aqui para aparecer rapido na Home.
    // - notifications_* guarda a preferencia local de lembrete de estudo.
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

  //  DDL · Tabela: questions

  // Bloco DB-2 - cria a tabela principal das questoes.
  // A tela de questoes, simulados e revisao leem desta tabela.
  Future<void> _createTableQuestions(Database db) async {
    // Detalhe:
    // - question_text e o enunciado textual, sem depender de imagem.
    // - subject/topic alimentam filtros, estatisticas e pontos fracos.
    // - exam_source guarda algo como "ENEM 2023" para filtrar por prova.
    // - CHECK(correct_option...) impede gabarito fora de A/B/C/D/E.
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

  //  DDL · Tabela: attempts

  // Bloco DB-3 - cria a tabela normalizada das alternativas.
  // Mesmo existindo option_a...option_e em questions, essa tabela facilita
  // consultas futuras e deixa cada alternativa como uma linha propria.
  Future<void> _createTableQuestionAlternatives(Database db) async {
    // Detalhe:
    // - ON DELETE CASCADE remove alternativas quando a questao e apagada.
    // - UNIQUE(question_id, letter) impede duas alternativas "A" na mesma questao.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableQuestionAlternatives} (
        ${DbConstants.colAlternativeId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colAlternativeQuestionId} INTEGER NOT NULL REFERENCES ${DbConstants.tableQuestions}(id) ON DELETE CASCADE,
        ${DbConstants.colAlternativeLetter} TEXT NOT NULL CHECK(${DbConstants.colAlternativeLetter} IN ('A','B','C','D','E')),
        ${DbConstants.colAlternativeText} TEXT NOT NULL,
        ${DbConstants.colAlternativeIsCorrect} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colAlternativeCreatedAt} TEXT NOT NULL,
        UNIQUE(${DbConstants.colAlternativeQuestionId}, ${DbConstants.colAlternativeLetter})
      )
    ''');
  }

  // Bloco DB-4 - cria a tabela de favoritas por usuario.
  // Hoje o app usa um perfil principal, mas essa estrutura ja suporta mais usuarios.
  Future<void> _createTableFavoriteQuestions(Database db) async {
    // Detalhe:
    // A chave primaria composta user_id + question_id impede favorito duplicado.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableFavoriteQuestions} (
        ${DbConstants.colFavoriteUserId} INTEGER NOT NULL REFERENCES ${DbConstants.tableUsers}(id) ON DELETE CASCADE,
        ${DbConstants.colFavoriteQuestionId} INTEGER NOT NULL REFERENCES ${DbConstants.tableQuestions}(id) ON DELETE CASCADE,
        ${DbConstants.colFavoriteCreatedAt} TEXT NOT NULL,
        PRIMARY KEY (${DbConstants.colFavoriteUserId}, ${DbConstants.colFavoriteQuestionId})
      )
    ''');
  }

  // Bloco DB-5 - cria a tabela de configuracoes simples.
  // Usada para guardar metadados, como a versao do banco offline do ENEM.
  Future<void> _createTableAppSettings(Database db) async {
    // Detalhe:
    // key e PRIMARY KEY, entao inserir a mesma key com replace atualiza o valor.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableAppSettings} (
        ${DbConstants.colAppSettingKey} TEXT PRIMARY KEY,
        ${DbConstants.colAppSettingValue} TEXT NOT NULL,
        ${DbConstants.colAppSettingUpdatedAt} TEXT NOT NULL
      )
    ''');
  }

  // Bloco DB-6 - cria a tabela de tentativas/respostas.
  // Cada resposta confirmada pelo aluno pode gerar uma linha aqui.
  Future<void> _createTableAttempts(Database db) async {
    // Detalhe:
    // - selected_option guarda o que o aluno marcou.
    // - is_correct guarda 0/1 para os calculos de acerto.
    // - latitude/longitude/location_name sao opcionais e vem do GPS.
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

  //  DDL · Tabela: study_sessions

  // Bloco DB-7 - cria estatisticas agregadas por categoria/disciplina.
  // Ela evita recalcular tudo sempre que a tela de estatisticas abre.
  Future<void> _createTableUserStats(Database db) async {
    // Detalhe:
    // UNIQUE(user_id, category) garante uma linha por disciplina para cada usuario.
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

  // Bloco DB-8 - cria tabela de sessoes de estudo/simulados.
  // Um simulado finalizado vira uma linha aqui para aparecer no historico.
  Future<void> _createTableStudySessions(Database db) async {
    // Detalhe:
    // subjects_json guarda a lista de materias em texto JSON.
    // finished_at pode ser null enquanto a sessao ainda nao foi encerrada.
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

  // Bloco DB-9 - cria progresso de estudo do usuario.
  // Guarda streak, meta semanal e quantas questoes ja foram feitas na semana.
  Future<void> _createTableStudyProgress(Database db) async {
    // Detalhe:
    // user_id e PRIMARY KEY porque cada usuario tem apenas um progresso atual.
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

  // Bloco DB-10 - cria tabela de locais de estudo.
  // Ela agrupa coordenadas proximas para dizer onde o aluno mais estuda.
  Future<void> _createTableStudyPlaces(Database db) async {
    // Detalhe:
    // last_seen_at muda quando o app reconhece que o aluno estudou no mesmo lugar.
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

  // Bloco DB-11 - cria historico de questoes usadas em simulados.
  // Serve para nao sortear sempre as mesmas questoes.
  Future<void> _createTableSimuladoQuestionHistory(Database db) async {
    // Detalhe:
    // question_id e PRIMARY KEY porque cada questao precisa de um unico contador.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableSimuladoQuestionHistory} (
        ${DbConstants.colSimuladoHistoryQuestionId} INTEGER PRIMARY KEY REFERENCES ${DbConstants.tableQuestions}(id) ON DELETE CASCADE,
        ${DbConstants.colSimuladoHistoryLastSelectedAt} TEXT NOT NULL,
        ${DbConstants.colSimuladoHistorySelectionCount} INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  //  DDL · Índices para performance

  Future<void> _createIndexes(Database db) async {
    // Bloco DB-12 - indices sao atalhos que deixam consultas mais rapidas.
    // Eles nao mudam os dados; apenas ajudam o SQLite a encontrar linhas.
    // Exemplos neste app: filtro por disciplina, ENEM especifico, favoritas,
    // historico semanal e simulados recentes.
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
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_alternatives_question
        ON ${DbConstants.tableQuestionAlternatives}(${DbConstants.colAlternativeQuestionId}, ${DbConstants.colAlternativeLetter})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_favorites_question
        ON ${DbConstants.tableFavoriteQuestions}(${DbConstants.colFavoriteQuestionId})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_app_settings_updated_at
        ON ${DbConstants.tableAppSettings}(${DbConstants.colAppSettingUpdatedAt})
    ''');
  }

  //  SEED · Questões de exemplo para demonstração

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

  //  CRUD · USERS

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

  Future<int> updateUserName(
      {required int userId, required String name}) async {
    final db = await database;
    return db.update(
      DbConstants.tableUsers,
      {DbConstants.colUserName: name},
      where: '${DbConstants.colUserId} = ?',
      whereArgs: [userId],
    );
  }

  //  CRUD · QUESTIONS
  Future<int> updateUserAvatar({
    required int userId,
    String? avatarPath,
  }) async {
    // Bloco 12 - atualiza somente a coluna avatar do usuario.
    // avatarPath pode ser null, caminho antigo ou data:image/...;base64.
    final db = await database;
    return db.update(
      DbConstants.tableUsers,
      {DbConstants.colUserAvatar: avatarPath},
      where: '${DbConstants.colUserId} = ?',
      whereArgs: [userId],
    );
  }

  Future<int> insertQuestion(Question question) async {
    // Bloco 13 - antes de salvar, valida se a questao e usavel offline.
    // Isso evita questoes sem alternativa ou dependentes de imagem.
    if (!_isUsableQuestion(question)) {
      throw ArgumentError('Questao incompleta ou dependente de imagem.');
    }

    final db = await database;
    // Bloco 14 - usa transacao para salvar questao e alternativas juntas.
    // Se algo falhar, nada fica salvo pela metade.
    return db.transaction((txn) async {
      // Bloco 14.1 - converte entidade de dominio para model do banco.
      final model = QuestionModel.fromEntity(question);

      // Bloco 14.2 - insere questao principal.
      final questionId = await txn.insert(
        DbConstants.tableQuestions,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      // Bloco 14.3 - salva alternativas na tabela normalizada.
      await _replaceQuestionAlternatives(
        txn, //trans
        model.copyWith(id: questionId),
      );
      // Bloco 14.4 - se a questao ja veio favorita, registra favorito.
      if (question.isFavorite) {
        await _setFavoriteInTransaction(
          txn,
          userId: 1,
          questionId: questionId,
          isFavorite: true,
        );
      }
      return questionId;
    });
  }

  Future<List<QuestionModel>> getAllQuestions() async {
    // Bloco 15 - busca todas as questoes ordenando pelas mais recentes.
    final db = await database;
    final maps = await db.query(
      DbConstants.tableQuestions,
      orderBy: '${DbConstants.colQuestionCreatedAt} DESC',
    );
    return maps.map(QuestionModel.fromMap).toList();
  }

  /// Busca com filtros combinados (matéria, dificuldade, fonte, favoritos)
  Future<QuestionModel?> getQuestionById(int id) async {
    // Bloco 16 - busca uma questao especifica pelo id.
    final db = await database;
    final maps = await db.query(
      DbConstants.tableQuestions,
      where: '${DbConstants.colQuestionId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return QuestionModel.fromMap(maps.first);
  }

  Future<List<QuestionModel>> getFilteredQuestions({
    List<String>? subjects,
    List<int>? difficulties, // 1=Fácil, 2=Médio, 3=Difícil
    String? examSource,
    bool? favoritesOnly,
    String? searchText,
    int? limit,
  }) async {
    // Bloco 17 - monta uma consulta dinamica com filtros opcionais.
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    // Bloco 17.1 - filtro por materias.
    if (subjects != null && subjects.isNotEmpty) {
      final placeholders = List.filled(subjects.length, '?').join(',');
      whereClauses.add('${DbConstants.colQuestionSubject} IN ($placeholders)');
      whereArgs.addAll(subjects);
    }

    // Bloco 17.2 - filtro por dificuldade.
    if (difficulties != null && difficulties.isNotEmpty) {
      final placeholders = List.filled(difficulties.length, '?').join(',');
      whereClauses.add(
        '${DbConstants.colQuestionDifficulty} IN ($placeholders)',
      );
      whereArgs.addAll(difficulties);
    }

    // Bloco 17.3 - filtro por prova/fonte, exemplo: ENEM 2023.
    if (examSource != null && examSource.isNotEmpty) {
      whereClauses.add('${DbConstants.colQuestionExamSource} = ?');
      whereArgs.add(examSource);
    }

    // Bloco 17.4 - filtro de favoritas.
    // Considera tanto a coluna antiga quanto a tabela normalizada.
    if (favoritesOnly == true) {
      whereClauses.add('''
        (
          ${DbConstants.colQuestionIsFavorite} = 1
          OR ${DbConstants.colQuestionId} IN (
            SELECT ${DbConstants.colFavoriteQuestionId}
            FROM ${DbConstants.tableFavoriteQuestions}
            WHERE ${DbConstants.colFavoriteUserId} = 1
          )
        )
      ''');
    }

    // Bloco 17.5 - busca textual em enunciado, topico, materia e fonte.
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

    // Bloco 17.6 - junta todas as condicoes com AND.
    final whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    // Bloco 17.7 - quando nao filtra por ano, mistura questoes entre anos.
    // Isso evita que a lista inicial mostre questoes de um unico ENEM.
    if (limit != null && limit > 0 && examSource == null) {
      return _getBalancedFilteredQuestions(
        db,
        whereClauses: whereClauses,
        whereArgs: whereArgs,
        limit: limit,
      );
    }

    // Bloco 17.8 - consulta normal quando ha filtro de ENEM especifico.
    final maps = await db.query(
      DbConstants.tableQuestions,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy:
          '${DbConstants.colQuestionYear} DESC, ${DbConstants.colQuestionId} ASC',
      limit: limit,
    );

    return maps.map(QuestionModel.fromMap).toList();
  }

  Future<List<QuestionModel>> _getBalancedFilteredQuestions(
    Database db, {
    required List<String> whereClauses,
    required List<dynamic> whereArgs,
    required int limit,
  }) async {
    // Bloco 18 - busca anos distintos dentro dos filtros.
    // Depois distribui a lista inicial entre esses anos.
    final distinctWhereClauses = <String>[
      ...whereClauses,
      '${DbConstants.colQuestionYear} IS NOT NULL',
    ];

    // Bloco 18.1 - consulta os anos disponiveis.
    final distinctRows = await db.query(
      DbConstants.tableQuestions,
      columns: [DbConstants.colQuestionYear],
      where: distinctWhereClauses.join(' AND '),
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      groupBy: DbConstants.colQuestionYear,
      orderBy: '${DbConstants.colQuestionYear} DESC',
    );

    // Bloco 18.2 - transforma as linhas em lista de anos inteiros.
    final years = distinctRows
        .map((row) => _asInt(row[DbConstants.colQuestionYear]))
        .whereType<int>()
        .toList(growable: false);

    // Bloco 18.3 - se nao encontrou anos, cai para uma consulta comum.
    if (years.isEmpty) {
      final maps = await db.query(
        DbConstants.tableQuestions,
        where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy:
            '${DbConstants.colQuestionYear} DESC, ${DbConstants.colQuestionId} ASC',
        limit: limit,
      );
      return maps.map(QuestionModel.fromMap).toList();
    }

    // Bloco 18.4 - calcula quantas questoes pegar de cada ano.
    final perYear = math.max(1, (limit / years.length).ceil());
    final questionsByYear = <int, List<QuestionModel>>{};

    // Bloco 18.5 - carrega um lote de questoes para cada ano.
    for (final year in years) {
      final yearWhereClauses = <String>[
        ...whereClauses,
        '${DbConstants.colQuestionYear} = ?',
      ];
      final yearRows = await db.query(
        DbConstants.tableQuestions,
        where: yearWhereClauses.join(' AND '),
        whereArgs: <dynamic>[...whereArgs, year],
        orderBy: '${DbConstants.colQuestionId} ASC',
        limit: perYear,
      );
      questionsByYear[year] = yearRows.map(QuestionModel.fromMap).toList();
    }

    // Bloco 18.6 - intercala questoes ano por ano.
    // Exemplo: 2025, 2024, 2023, depois volta para 2025.
    final selected = <QuestionModel>[];
    var addedInRound = true;
    while (selected.length < limit && addedInRound) {
      addedInRound = false;
      for (final year in years) {
        final yearQuestions = questionsByYear[year];
        if (yearQuestions == null || yearQuestions.isEmpty) continue;

        selected.add(yearQuestions.removeAt(0));
        addedInRound = true;
        if (selected.length == limit) break;
      }
    }

    // Bloco 18.7 - se faltou completar o limite, busca questoes extras.
    if (selected.length < limit) {
      final selectedIds = selected
          .map((question) => question.id)
          .whereType<int>()
          .toList(growable: false);
      final topUpWhereClauses = <String>[...whereClauses];
      final topUpArgs = <dynamic>[...whereArgs];
      if (selectedIds.isNotEmpty) {
        topUpWhereClauses.add(
          '${DbConstants.colQuestionId} NOT IN (${List.filled(selectedIds.length, '?').join(',')})',
        );
        topUpArgs.addAll(selectedIds);
      }

      final topUpRows = await db.query(
        DbConstants.tableQuestions,
        where: topUpWhereClauses.isNotEmpty
            ? topUpWhereClauses.join(' AND ')
            : null,
        whereArgs: topUpArgs.isNotEmpty ? topUpArgs : null,
        orderBy:
            '${DbConstants.colQuestionYear} DESC, ${DbConstants.colQuestionId} ASC',
        limit: limit - selected.length,
      );
      selected.addAll(topUpRows.map(QuestionModel.fromMap));
    }

    return selected.take(limit).toList(growable: false);
  }

  Future<List<QuestionModel>> getBalancedSimuladoQuestions({
    required int quantity,
    List<String>? subjects,
  }) async {
    // Bloco 19 - se quantidade invalida, retorna lista vazia.
    if (quantity <= 0) return const <QuestionModel>[];

    // Bloco 20 - monta filtros fortes para simulado.
    // Aqui exigimos questoes ENEM, textuais, completas e com gabarito valido.
    final db = await database;
    final random = math.Random.secure();
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

    // Bloco 20.1 - se usuario selecionou materias, aplica filtro.
    if (subjects != null && subjects.isNotEmpty) {
      final placeholders = List.filled(subjects.length, '?').join(',');
      whereClauses.add(
        'q.${DbConstants.colQuestionSubject} IN ($placeholders)',
      );
      whereArgs.addAll(subjects);
    }

    // Bloco 20.2 - consulta questoes e junta historico de uso em simulados.
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

    // Bloco 20.3 - transforma linhas SQL em candidatos de simulado.
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
        .toList(growable: false)
      ..shuffle(random);

    // Bloco 20.4 - separa questoes nunca usadas das ja usadas.
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

    // Bloco 20.5 - prioriza questoes nunca vistas.
    final selected = <_SimuladoCandidate>[
      ..._takeBalancedQuestions(unseen, quantity),
    ];

    // Bloco 20.6 - se nao tiver questoes novas suficientes, usa antigas menos recentes.
    if (selected.length < quantity) {
      selected.addAll(
        _takeBalancedQuestions(seen, quantity - selected.length),
      );
    }

    // Bloco 20.7 - registra que essas questoes foram usadas no simulado.
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
    // Bloco 21 - seleciona questoes balanceando por ano.
    if (quantity <= 0 || candidates.isEmpty) {
      return const <_SimuladoCandidate>[];
    }

    // Bloco 21.1 - agrupa candidatos por ano.
    final questionsByYear = <int, List<_SimuladoCandidate>>{};
    for (final candidate in candidates) {
      questionsByYear.putIfAbsent(candidate.year, () => []).add(candidate);
    }

    // Bloco 21.2 - embaralha questoes dentro de cada ano.
    final random = math.Random.secure();
    for (final questions in questionsByYear.values) {
      questions.shuffle(random);
    }

    // Bloco 21.3 - embaralha a ordem dos anos.
    final years = questionsByYear.keys.toList()..shuffle(random);
    final selected = <_SimuladoCandidate>[];

    // Bloco 21.4 - pega uma questao de cada ano por rodada.
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
    final maps = await db.rawQuery(
      '''
      SELECT DISTINCT q.*
      FROM ${DbConstants.tableQuestions} q
      LEFT JOIN ${DbConstants.tableFavoriteQuestions} f
        ON f.${DbConstants.colFavoriteQuestionId} = q.${DbConstants.colQuestionId}
      WHERE q.${DbConstants.colQuestionIsFavorite} = 1
        OR f.${DbConstants.colFavoriteUserId} = 1
      ORDER BY q.${DbConstants.colQuestionCreatedAt} DESC
      ''',
    );
    return maps.map(QuestionModel.fromMap).toList();
  }

  Future<int> toggleFavorite(int questionId, bool newValue) async {
    final db = await database;
    return db.transaction((txn) async {
      final updated = await txn.update(
        DbConstants.tableQuestions,
        {DbConstants.colQuestionIsFavorite: newValue ? 1 : 0},
        where: '${DbConstants.colQuestionId} = ?',
        whereArgs: [questionId],
      );
      await _setFavoriteInTransaction(
        txn,
        userId: 1,
        questionId: questionId,
        isFavorite: newValue,
      );
      return updated;
    });
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

  Future<String?> getAppSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      DbConstants.tableAppSettings,
      columns: [DbConstants.colAppSettingValue],
      where: '${DbConstants.colAppSettingKey} = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first[DbConstants.colAppSettingValue]?.toString();
  }

  Future<void> setAppSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      DbConstants.tableAppSettings,
      {
        DbConstants.colAppSettingKey: key,
        DbConstants.colAppSettingValue: value,
        DbConstants.colAppSettingUpdatedAt: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ══════════════════════════════════════════════════════════
  //  CRUD · ATTEMPTS
  // ══════════════════════════════════════════════════════════

  Future<int> insertAttempt(Attempt attempt) async {
    // Bloco DB-13 - salva uma tentativa de resposta.
    // Essa e uma das operacoes mais importantes do app: ela registra a resposta
    // e tambem atualiza os numeros que aparecem na Home, Perfil e Estatisticas.
    final db = await database;
    final model = AttemptModel.fromEntity(attempt);

    // Bloco DB-13.1 - transacao garante consistencia.
    // Se qualquer update falhar, o SQLite desfaz tudo e evita dados pela metade.
    return await db.transaction((txn) async {
      // Bloco DB-13.2 - primeiro salva a resposta individual.
      final attemptId = await txn.insert(
        DbConstants.tableAttempts,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      // Bloco DB-13.3 - atualiza progresso semanal e streak dentro da mesma transacao.
      final progress = await _recordAnsweredQuestionInTransaction(
        txn,
        userId: attempt.userId,
        answeredAt: attempt.answeredAt,
      );

      // Bloco DB-13.4 - incrementa totais no perfil do usuario.
      // total_correct soma 1 apenas se a tentativa foi correta.
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

      // Bloco DB-13.5 - atualiza estatistica agregada por disciplina.
      await _upsertUserStatsForAttempt(txn, attempt);

      // Bloco DB-13.6 - devolve o id da tentativa criada.
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
    // Bloco DB-14 - calcula porcentagem de acertos por disciplina.
    // A query cruza attempts com questions porque a disciplina esta na questao,
    // enquanto o acerto/erro esta na tentativa.
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

    // Bloco DB-14.1 - transforma cada linha SQL em Map<String, double>.
    // Exemplo final: {"Matematica": 0.78, "Linguagens": 0.85}.
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
    // Bloco DB-15 - agrupa respostas por dia nos ultimos 7 dias.
    // DATE(answered_at) corta o horario e deixa somente o dia.
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
    // Bloco DB-16 - calcula os locais onde o aluno teve melhor desempenho.
    // A query usa location_name salvo nas tentativas pelo servico de GPS.
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
    // Bloco DB-17 - sorteia uma questao que o usuario ainda nao respondeu hoje.
    // O NOT IN remove do sorteio as questoes ja respondidas na data atual.
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
    // Bloco DB-29 - le o progresso atual do usuario.
    // Se a semana virou, ele normaliza o contador semanal antes de devolver.
    final db = await database;
    final rows = await db.query(
      DbConstants.tableStudyProgress,
      where: '${DbConstants.colProgressUserId} = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return StudyProgress.initial();

    final current = _studyProgressFromMap(rows.first);
    // Confere se o registro ainda pertence a semana atual.
    final normalized = _resetProgressWeekIfNeeded(current, DateTime.now());
    if (normalized.weekStartedAt != current.weekStartedAt ||
        normalized.weeklyAnsweredQuestions != current.weeklyAnsweredQuestions) {
      // Se precisou resetar a semana, ja grava o valor normalizado.
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
    // Bloco DB-30 - registra uma questao respondida sem necessariamente
    // salvar uma Attempt completa. Usado por fluxos mais simples de progresso.
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
    // Bloco DB-31 - altera a meta semanal de questoes.
    // clamp(1, 999) evita meta zero ou valores absurdamente altos.
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
    // Bloco DB-18 - atualiza/importa uma lista de questoes.
    // Usado quando o repositorio carrega questoes dos JSONs locais do ENEM.
    if (questions.isEmpty) {
      // Lista vazia nao precisa abrir transacao.
      return const QuestionUpsertResult(inserted: 0, updated: 0);
    }

    final db = await database;
    return db.transaction((txn) async {
      // Primeiro insere/atualiza o que veio do JSON.
      final result = await _upsertQuestions(txn, questions);

      // Depois limpa registros invalidos/duplicados que possam ter sobrado.
      await _cleanQuestionBank(txn);
      return result;
    });
  }

  Future<void> cleanQuestionBank() async {
    final db = await database;
    await db.transaction(_cleanQuestionBank);
  }

  Future<QuestionUpsertResult> replaceQuestionsFromSource({
    required String examSource,
    required List<Question> questions,
  }) async {
    // Bloco DB-19 - substitui o conjunto de questoes de uma prova/fonte.
    // Exemplo: ao importar ENEM 2023 completo, remove do banco as questoes
    // antigas de ENEM 2023 que nao existem mais no JSON atual.
    final db = await database;
    return db.transaction((txn) async {
      // Insere novas questoes e atualiza as que ja existiam.
      final result = await _upsertQuestions(txn, questions);

      // topics representa as questoes que continuam existindo na fonte atual.
      final topics = questions.map((question) => question.topic).toSet();

      if (topics.isEmpty) {
        // Se nao veio nenhuma questao, remove tudo daquela fonte.
        await txn.delete(
          DbConstants.tableQuestions,
          where: '${DbConstants.colQuestionExamSource} = ?',
          whereArgs: [examSource],
        );
        await _cleanQuestionBank(txn);
        return result;
      }

      // Remove questoes da mesma fonte que nao vieram nessa importacao.
      final placeholders = List.filled(topics.length, '?').join(',');
      await txn.delete(
        DbConstants.tableQuestions,
        where:
            '${DbConstants.colQuestionExamSource} = ? AND ${DbConstants.colQuestionTopic} NOT IN ($placeholders)',
        whereArgs: [examSource, ...topics],
      );
      await _cleanQuestionBank(txn);
      return result;
    });
  }

  Future<QuestionUpsertResult> _upsertQuestions(
    Transaction txn,
    List<Question> questions,
  ) async {
    // Bloco DB-20 - percorre as questoes uma por uma e decide insert ou update.
    var inserted = 0;
    var updated = 0;

    for (final question in questions) {
      // Ignora questoes que nao podem funcionar offline.
      // Exemplo: sem alternativas completas ou dependente de imagem.
      if (!_isUsableQuestion(question)) continue;

      // Procura questao existente pela combinacao fonte + topico.
      // Isso evita duplicar a mesma questao quando o JSON e importado novamente.
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
        // Bloco DB-20.1 - nao existe ainda: insere como nova questao.
        final questionId = await txn.insert(
          DbConstants.tableQuestions,
          QuestionModel.fromEntity(question).toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        // Depois de inserir, salva alternativas normalizadas.
        await _replaceQuestionAlternatives(
          txn,
          question.copyWith(id: questionId),
        );
        // Tambem sincroniza favorito, caso a entidade ja venha favorita.
        await _setFavoriteInTransaction(
          txn,
          userId: 1,
          questionId: questionId,
          isFavorite: question.isFavorite,
        );
        inserted++;
        continue;
      }

      // Bloco DB-20.2 - ja existe: atualiza mantendo dados locais importantes.
      final stored = existing.first;
      final model = QuestionModel.fromEntity(
        question.copyWith(
          id: stored[DbConstants.colQuestionId] as int?,
          // Mantem favorito que o usuario marcou localmente.
          isFavorite:
              (stored[DbConstants.colQuestionIsFavorite] as int? ?? 0) != 0,
          // Mantem data original de criacao da questao no banco.
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
      // Recria alternativas para refletir qualquer mudanca no JSON.
      await _replaceQuestionAlternatives(txn, model);
      // Garante que a tabela nova de favoritos continue coerente.
      await _setFavoriteInTransaction(
        txn,
        userId: 1,
        questionId: model.id!,
        isFavorite: model.isFavorite,
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

  Future<void> _cleanQuestionBank(DatabaseExecutor db) async {
    // Bloco DB-21 - faxina do banco de questoes.
    // Ela roda depois de importar JSON para manter apenas questoes validas.
    await _removeInvalidQuestionRecords(db);
    await _removeDuplicateQuestionRecords(db);
    await _syncFavoriteRowsFromQuestions(db);
  }

  Future<void> _removeInvalidQuestionRecords(DatabaseExecutor db) async {
    // Bloco DB-22 - remove questoes que nao podem ser usadas no app.
    // A regra vem de QuestionQualityPolicy, por exemplo: questao com imagem
    // obrigatoria, sem alternativa completa ou sem gabarito valido.
    final rows = await db.query(DbConstants.tableQuestions);

    for (final row in rows) {
      final question = QuestionModel.fromMap(row);
      if (_isUsableQuestion(question)) continue;

      await db.delete(
        DbConstants.tableQuestions,
        where: '${DbConstants.colQuestionId} = ?',
        whereArgs: [question.id],
      );
    }
  }

  Future<void> _removeDuplicateQuestionRecords(DatabaseExecutor db) async {
    // Bloco DB-23 - remove questoes duplicadas pelo conteudo.
    // Importante porque arquivos diferentes podem conter textos repetidos.
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
    // Guarda a primeira questao encontrada para cada "assinatura" de conteudo.
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

      // Se a duplicata estava favorita, transfere esse favorito para a original.
      if ((row[DbConstants.colQuestionIsFavorite] as int? ?? 0) != 0) {
        await db.update(
          DbConstants.tableQuestions,
          {DbConstants.colQuestionIsFavorite: 1},
          where: '${DbConstants.colQuestionId} = ?',
          whereArgs: [originalId],
        );
      }
      // Move favoritos normalizados da duplicata para a original.
      await _moveFavoriteRows(
        db,
        fromQuestionId: duplicateId,
        toQuestionId: originalId,
      );
      // Reaponta tentativas antigas para a questao original.
      await db.update(
        DbConstants.tableAttempts,
        {DbConstants.colAttemptQuestionId: originalId},
        where: '${DbConstants.colAttemptQuestionId} = ?',
        whereArgs: [duplicateId],
      );
      // Remove historico de simulado da duplicata.
      await db.delete(
        DbConstants.tableSimuladoQuestionHistory,
        where: '${DbConstants.colSimuladoHistoryQuestionId} = ?',
        whereArgs: [duplicateId],
      );
      // Finalmente apaga a questao duplicada.
      await db.delete(
        DbConstants.tableQuestions,
        where: '${DbConstants.colQuestionId} = ?',
        whereArgs: [duplicateId],
      );
    }
  }

  String _questionContentKey(Map<String, Object?> row) {
    return QuestionQualityPolicy.contentKey(QuestionModel.fromMap(row));
  }

  Future<void> _syncNormalizedQuestionTables(DatabaseExecutor db) async {
    // Bloco DB-24 - recria tabelas derivadas a partir da tabela questions.
    // Usado em migracoes e limpeza para manter alternativas/favoritos coerentes.
    await _syncQuestionAlternativesFromQuestions(db);
    await _syncFavoriteRowsFromQuestions(db);
  }

  Future<void> _syncQuestionAlternativesFromQuestions(
    DatabaseExecutor db,
  ) async {
    // Bloco DB-25 - para cada questao, recria suas linhas A/B/C/D/E.
    final rows = await db.query(DbConstants.tableQuestions);
    for (final row in rows) {
      await _replaceQuestionAlternatives(db, QuestionModel.fromMap(row));
    }
  }

  Future<void> _syncFavoriteRowsFromQuestions(DatabaseExecutor db) async {
    // Bloco DB-26 - copia favoritos antigos da coluna questions.is_favorite
    // para a tabela normalizada favorite_questions.
    // Isso preserva favoritos de bancos criados antes da tabela nova existir.
    final userId = await _resolveDefaultUserId(db);
    if (userId == null) return;

    final favoriteRows = await db.query(
      DbConstants.tableQuestions,
      columns: [DbConstants.colQuestionId],
      where: '${DbConstants.colQuestionIsFavorite} = 1',
    );
    for (final row in favoriteRows) {
      final questionId = _asInt(row[DbConstants.colQuestionId]);
      if (questionId == null) continue;
      await _setFavoriteInTransaction(
        db,
        userId: userId,
        questionId: questionId,
        isFavorite: true,
      );
    }
  }

  Future<void> _replaceQuestionAlternatives(
    DatabaseExecutor db,
    Question question,
  ) async {
    // Bloco DB-27 - substitui todas as alternativas de uma questao.
    // Estrategia simples e segura: apaga as antigas e insere as atuais.
    final questionId = question.id;
    if (questionId == null) return;

    // Remove alternativas antigas da questao.
    await db.delete(
      DbConstants.tableQuestionAlternatives,
      where: '${DbConstants.colAlternativeQuestionId} = ?',
      whereArgs: [questionId],
    );

    final now = DateTime.now().toIso8601String();
    for (final option in question.options.entries) {
      // Normaliza letra e texto para evitar gravar espacos desnecessarios.
      final letter = option.key.trim().toUpperCase();
      final text = option.value.trim();
      if (letter.isEmpty || text.isEmpty) continue;

      // Marca is_correct = 1 apenas na alternativa que bate com o gabarito.
      await db.insert(
        DbConstants.tableQuestionAlternatives,
        {
          DbConstants.colAlternativeQuestionId: questionId,
          DbConstants.colAlternativeLetter: letter,
          DbConstants.colAlternativeText: text,
          DbConstants.colAlternativeIsCorrect:
              letter == question.normalizedCorrectOption ? 1 : 0,
          DbConstants.colAlternativeCreatedAt: now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _setFavoriteInTransaction(
    DatabaseExecutor db, {
    required int userId,
    required int questionId,
    required bool isFavorite,
  }) async {
    // Bloco DB-28 - liga/desliga favorito na tabela normalizada.
    // Esse metodo recebe DatabaseExecutor para funcionar tanto com Database
    // quanto dentro de Transaction.
    if (!isFavorite) {
      // Se o usuario desfavoritou, remove a linha da tabela de favoritas.
      await db.delete(
        DbConstants.tableFavoriteQuestions,
        where:
            '${DbConstants.colFavoriteUserId} = ? AND ${DbConstants.colFavoriteQuestionId} = ?',
        whereArgs: [userId, questionId],
      );
      return;
    }

    // Antes de favoritar, confere se o usuario existe para respeitar FK.
    final userRows = await db.query(
      DbConstants.tableUsers,
      columns: [DbConstants.colUserId],
      where: '${DbConstants.colUserId} = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (userRows.isEmpty) return;

    // conflictAlgorithm.ignore evita erro se o favorito ja existe.
    await db.insert(
      DbConstants.tableFavoriteQuestions,
      {
        DbConstants.colFavoriteUserId: userId,
        DbConstants.colFavoriteQuestionId: questionId,
        DbConstants.colFavoriteCreatedAt: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _moveFavoriteRows(
    DatabaseExecutor db, {
    required int fromQuestionId,
    required int toQuestionId,
  }) async {
    final rows = await db.query(
      DbConstants.tableFavoriteQuestions,
      where: '${DbConstants.colFavoriteQuestionId} = ?',
      whereArgs: [fromQuestionId],
    );
    for (final row in rows) {
      final userId = _asInt(row[DbConstants.colFavoriteUserId]);
      if (userId == null) continue;
      await _setFavoriteInTransaction(
        db,
        userId: userId,
        questionId: toQuestionId,
        isFavorite: true,
      );
    }
    await db.delete(
      DbConstants.tableFavoriteQuestions,
      where: '${DbConstants.colFavoriteQuestionId} = ?',
      whereArgs: [fromQuestionId],
    );
  }

  Future<int?> _resolveDefaultUserId(DatabaseExecutor db) async {
    final rows = await db.query(
      DbConstants.tableUsers,
      columns: [DbConstants.colUserId],
      orderBy: '${DbConstants.colUserId} ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _asInt(rows.first[DbConstants.colUserId]);
  }

  // ══════════════════════════════════════════════════════════
  //  UTILITÁRIOS
  // ══════════════════════════════════════════════════════════

  bool _isUsableQuestion(Question question) {
    return QuestionQualityPolicy.isUsable(
      question,
      requireFiveAlternatives: _isEnemQuestion(question),
    );
  }

  bool _isEnemQuestion(Question question) {
    return question.examSource?.trim().toUpperCase().startsWith('ENEM') == true;
  }

  /// Fecha a conexao, usado principalmente pelos testes.
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
      await txn.delete(
        DbConstants.tableFavoriteQuestions,
        where: '${DbConstants.colFavoriteUserId} = ?',
        whereArgs: [userId],
      );
      await txn.update(
        DbConstants.tableQuestions,
        {DbConstants.colQuestionIsFavorite: 0},
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
    return getLocalFileSizeBytes(path);
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
    // Bloco DB-32 - atualiza streak e meta semanal dentro de uma transacao.
    // Recebe Transaction para ser usado junto com insertAttempt.
    final current = _resetProgressWeekIfNeeded(
      await _readStudyProgress(txn, userId),
      answeredAt,
    );
    final previousStudyDay = current.lastStudyDate;

    // Se ja estudou hoje, o streak nao aumenta de novo.
    final alreadyStudiedToday =
        previousStudyDay != null && _isSameDate(previousStudyDay, answeredAt);

    // Regra do streak:
    // - estudou hoje: mantem.
    // - estudou ontem: soma 1.
    // - ficou mais de um dia sem estudar: reinicia em 1.
    final nextStreak = alreadyStudiedToday
        ? current.currentStreak
        : _isYesterday(previousStudyDay, answeredAt)
            ? current.currentStreak + 1
            : 1;

    // Tambem soma uma questao na meta semanal.
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
    // Bloco DB-33 - grava o progresso no banco.
    // ConflictAlgorithm.replace funciona como "salvar por cima" porque user_id
    // e a chave primaria da tabela study_progress.
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
    // Bloco DB-34 - converte a linha do SQLite em entidade StudyProgress.
    // SQLite devolve Object?, entao usamos helpers _asInt/DateTime.tryParse.
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
    // Bloco DB-35 - verifica se a semana mudou.
    // A semana comeca na segunda-feira, calculada por _startOfWeek.
    final currentWeekStart = _startOfWeek(now);
    final storedWeekStart = progress.weekStartedAt;
    if (storedWeekStart != null &&
        _isSameDate(storedWeekStart, currentWeekStart)) {
      return progress;
    }
    // Se mudou a semana, zera apenas o contador semanal.
    // O streak continua, porque streak e por dias consecutivos, nao por semana.
    return progress.copyWith(
      weeklyAnsweredQuestions: 0,
      weekStartedAt: currentWeekStart,
    );
  }

  DateTime _startOfWeek(DateTime date) {
    // Bloco DB-36 - normaliza a data para a segunda-feira daquela semana.
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  bool _isSameDate(DateTime first, DateTime second) {
    // Bloco DB-37 - compara apenas ano/mes/dia, ignorando horario.
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isYesterday(DateTime? previous, DateTime now) {
    // Bloco DB-38 - confere se a ultima data de estudo foi exatamente ontem.
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
    // Bloco DB-39 - calcula distancia entre duas coordenadas GPS.
    // Usa a formula de Haversine, apropriada para distancia na superficie da Terra.
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
    // Bloco DB-40 - atualiza a tabela user_stats com base em uma tentativa.
    // Essa tabela guarda acumulados por disciplina para a tela Estatisticas.

    // Primeiro descobre a disciplina da questao respondida.
    final questionRows = await txn.query(
      DbConstants.tableQuestions,
      columns: [DbConstants.colQuestionSubject],
      where: '${DbConstants.colQuestionId} = ?',
      whereArgs: [attempt.questionId],
      limit: 1,
    );
    if (questionRows.isEmpty) return;

    // category aqui e a disciplina, por exemplo "Matematica".
    final category =
        (questionRows.first[DbConstants.colQuestionSubject] as String?) ??
            'Geral';
    final now = DateTime.now().toIso8601String();

    // Procura se ja existe estatistica desse usuario nessa disciplina.
    final existingRows = await txn.query(
      DbConstants.tableUserStats,
      where:
          '${DbConstants.colUserStatsUserId} = ? AND ${DbConstants.colUserStatsCategory} = ?',
      whereArgs: [attempt.userId, category],
      limit: 1,
    );

    // Incremento vale 1 para acerto e 0 para erro.
    final correctIncrement = attempt.isCorrect ? 1 : 0;
    if (existingRows.isEmpty) {
      // Bloco DB-40.1 - primeira resposta nessa disciplina:
      // cria a linha inicial da estatistica.
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

    // Bloco DB-40.2 - ja existe estatistica:
    // soma 1 no total respondido e soma correctIncrement no total correto.
    final existing = existingRows.first;
    final totalAnswered =
        ((existing[DbConstants.colUserStatsTotalAnswered] as int?) ?? 0) + 1;
    final totalCorrect =
        ((existing[DbConstants.colUserStatsTotalCorrect] as int?) ?? 0) +
            correctIncrement;

    // Recalcula taxa de acerto como totalCorrect / totalAnswered.
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
    // Bloco DB-41 - conversao segura para double.
    // SQLite pode devolver int, double, num ou string dependendo da query.
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int? _asInt(Object? value) {
    // Bloco DB-42 - conversao segura para int.
    // Retorna null quando nao consegue converter.
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
