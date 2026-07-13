import '../../domain/entities/enem_exam.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/i_question_repository.dart';
import '../../domain/services/question_quality_policy.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/local/enem_local_data_source.dart';

// Bloco 1 - implementacao concreta do contrato de questoes.
// O dominio conhece apenas IQuestionRepository. Esta classe faz a ponte real
// com o SQLite e com os arquivos JSON offline do ENEM.
class QuestionRepositoryImpl implements IQuestionRepository {
  // Bloco 2 - construtor com dependencias opcionais.
  // Em producao usa os padroes; em testes pode receber banco ou datasource fake.
  QuestionRepositoryImpl({
    DatabaseHelper? dbHelper,
    EnemLocalDataSource? enemLocalDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _enemLocalDataSource =
            enemLocalDataSource ?? const EnemLocalDataSource();

  // Bloco 3 - versao do banco local.
  // Se os JSONs forem alterados, mudar esta string forca uma nova importacao.
  static const String _localEnemBankVersion = 'enem_text_bank_2009_2025_v2';

  // Bloco 4 - chaves salvas na tabela de configuracoes do app.
  static const String _localEnemBankVersionKey = 'local_enem_bank_version';
  static const String _localEnemBankYearsKey = 'local_enem_bank_years';

  // Bloco 5 - gateway para SQLite.
  final DatabaseHelper _dbHelper;

  // Bloco 6 - leitor dos assets JSON do ENEM.
  final EnemLocalDataSource _enemLocalDataSource;

  @override
  Future<LocalEnemBankSyncResult> ensureLocalEnemBank() async {
    // Bloco 7 - primeiro verifica se o banco local ja foi importado.
    final storedVersion =
        await _dbHelper.getAppSetting(_localEnemBankVersionKey);
    final questionCount = await _dbHelper.getTotalQuestionsCount();

    // Bloco 8 - se a versao bate e ja existem questoes, nao importa de novo.
    // Isso evita travar a tela de questoes toda vez que o app abre.
    if (storedVersion == _localEnemBankVersion && questionCount > 0) {
      return LocalEnemBankSyncResult(
        imported: 0,
        updated: 0,
        skipped: 0,
        totalFetched: questionCount,
        years: _parseImportedYears(
          await _dbHelper.getAppSetting(_localEnemBankYearsKey),
        ),
        didImport: false,
      );
    }

    // Bloco 9 - lista os anos/provas disponiveis nos arquivos locais.
    final exams = await _enemLocalDataSource.listExams();

    // Bloco 10 - contadores para montar o resultado final da importacao.
    var imported = 0;
    var updated = 0;
    var skipped = 0;
    var totalFetched = 0;
    final importedYears = <int>[];

    // Bloco 11 - importa cada ano do ENEM encontrado no JSON local.
    for (final exam in exams) {
      final result = await syncEnemQuestions(year: exam.year, limit: 0);
      imported += result.imported;
      updated += result.updated;
      skipped += result.skipped;
      totalFetched += result.totalFetched;
      importedYears.add(result.year);
    }

    // Bloco 12 - remove duplicatas ou registros ruins que sobraram.
    await _dbHelper.cleanQuestionBank();

    // Bloco 13 - grava metadados para a proxima abertura do app saber
    // que o banco offline ja esta preparado.
    await _dbHelper.setAppSetting(
      _localEnemBankVersionKey,
      _localEnemBankVersion,
    );
    await _dbHelper.setAppSetting(
      _localEnemBankYearsKey,
      importedYears.join(','),
    );
    await _dbHelper.setAppSetting(
      'local_enem_bank_imported_at',
      DateTime.now().toIso8601String(),
    );

    // Bloco 14 - devolve para o Provider um resumo da sincronizacao local.
    return LocalEnemBankSyncResult(
      imported: imported,
      updated: updated,
      skipped: skipped,
      totalFetched: totalFetched,
      years: importedYears,
      didImport: true,
    );
  }

  @override
  Future<EnemQuestionSyncResult> syncEnemQuestions({
    required int year,
    int limit = 0,
    String? language,
  }) async {
    // Bloco 15 - carrega questoes do JSON offline.
    // Aqui nao existe chamada para API externa.
    final localQuestions = await _enemLocalDataSource.loadQuestions(
      year: year,
      limit: limit,
      language: language,
    );

    // Bloco 16 - prepara contadores e conjuntos para evitar duplicatas.
    var skipped = 0;
    final seenNaturalKeys = <String>{};
    final seenContent = <String>{};
    final questionsToImport = <Question>[];

    // Bloco 17 - percorre as questoes lidas do JSON.
    for (final localQuestion in localQuestions) {
      // Bloco 17.1 - descarta questoes incompletas ou dependentes de imagem.
      if (!localQuestion.canBecomeQuestion) {
        skipped++;
        continue;
      }

      // Bloco 17.2 - converte o registro local em entidade de dominio.
      final question = localQuestion.toQuestion();
      final naturalKey = '${localQuestion.year}|${localQuestion.index}';
      final contentKey = _questionContentKey(question);

      // Bloco 17.3 - evita repetir a mesma questao pelo numero ou pelo texto.
      if (!seenNaturalKeys.add(naturalKey) || !seenContent.add(contentKey)) {
        skipped++;
        continue;
      }
      questionsToImport.add(question);
    }

    // Bloco 18 - define como salvar.
    // Importacao completa de um ano substitui as questoes daquela fonte.
    // Importacao parcial usa upsert para atualizar sem apagar o restante.
    final result = language == null && limit <= 0
        ? await _dbHelper.replaceQuestionsFromSource(
            examSource: 'ENEM $year',
            questions: questionsToImport,
          )
        : await _dbHelper.upsertQuestionsBySourceAndTopic(questionsToImport);

    // Bloco 19 - devolve o resumo da importacao daquele ano.
    return EnemQuestionSyncResult(
      year: year,
      imported: result.inserted,
      updated: result.updated,
      skipped: skipped,
      totalFetched: localQuestions.length,
    );
  }

  @override
  Future<int> insertQuestion(Question question) {
    // Bloco 20 - salva uma questao manual/mock no banco local.
    return _dbHelper.insertQuestion(question);
  }

  @override
  Future<void> seedMockQuestions({bool force = false}) async {
    // Bloco 21 - cria questoes falsas apenas quando necessario.
    // Serve como fallback para o app abrir com conteudo mesmo antes do JSON.
    if (!force) {
      final existing = await _dbHelper.getFilteredQuestions(
        searchText: 'Uma funcao',
        limit: 1,
      );
      if (existing.isNotEmpty) return;
    }

    // Bloco 22 - insere cada questao mock individualmente.
    for (final question in _mockQuestions()) {
      await _dbHelper.insertQuestion(question);
    }
  }

  @override
  Future<List<Question>> getQuestions() async {
    // Bloco 23 - metodo antigo mantido para compatibilidade.
    return _dbHelper.getAllQuestions();
  }

  @override
  Future<List<Question>> getAllQuestions() async {
    // Bloco 24 - busca todas as questoes do SQLite.
    return _dbHelper.getAllQuestions();
  }

  @override
  Future<List<Question>> getQuestionsByFilter({
    String? subject,
    String? vestibular,
    List<String>? subjects,
    List<int>? difficulties,
    String? examSource,
    bool favoritesOnly = false,
    String? searchText,
    int? limit,
  }) async {
    // Bloco 25 - junta parametros antigos e novos em um formato unico.
    final resolvedSubjects = subjects ??
        (subject != null && subject.isNotEmpty ? <String>[subject] : null);
    final resolvedExamSource = examSource ?? vestibular;

    // Bloco 26 - expande aliases de disciplina antes de consultar.
    // Exemplo: "Matematica" tambem busca versoes com acento.
    return _dbHelper.getFilteredQuestions(
      subjects: _expandSubjectAliases(resolvedSubjects),
      difficulties: difficulties,
      examSource: resolvedExamSource,
      favoritesOnly: favoritesOnly,
      searchText: searchText,
      limit: limit,
    );
  }

  @override
  Future<List<Question>> getSimuladoQuestions({
    required int quantity,
    List<String>? subjects,
  }) {
    // Bloco 27 - busca questoes para simulado com distribuicao mais equilibrada.
    return _dbHelper.getBalancedSimuladoQuestions(
      quantity: quantity,
      subjects: _expandSubjectAliases(subjects),
    );
  }

  @override
  Future<List<Question>> getWrongQuestions(int userId) {
    // Bloco 28 - busca as questoes erradas pelo usuario para revisao.
    return _dbHelper.getWrongQuestions(userId);
  }

  @override
  Future<List<Question>> getFavoriteQuestions() {
    // Bloco 29 - busca as questoes favoritadas.
    return _dbHelper.getFavoriteQuestions();
  }

  @override
  Future<int> toggleFavorite(int questionId, bool isFavorite) {
    // Bloco 30 - altera o favorito no banco.
    return _dbHelper.toggleFavorite(questionId, isFavorite);
  }

  @override
  Future<int> toggleFavoriteQuestion(int questionId, bool isFavorite) {
    // Bloco 31 - alias para chamadas que usam outro nome.
    return toggleFavorite(questionId, isFavorite);
  }

  @override
  Future<int> getTotalQuestionsCount() async {
    // Bloco 32 - total usado pela Home/Questao para mostrar tamanho do banco.
    return _dbHelper.getTotalQuestionsCount();
  }

  @override
  Future<Question?> getDailyChallenge(int userId) async {
    // Bloco 33 - desafio diario evitando repetir questoes ja respondidas hoje.
    return _dbHelper.getDailyChallenge(userId);
  }

  List<Question> _mockQuestions() {
    // Bloco 34 - dados falsos para demonstracao e teste rapido.
    return <Question>[
      Question(
        text:
            'Uma funcao f(x) = ax^2 + bx + c tem raizes -2 e 3, e vertice em (0,5; -6,25). Determine a forma fatorada.',
        subject: 'Matematica',
        topic: 'Funcoes Quadraticas',
        difficulty: 2,
        year: 2023,
        examSource: 'ENEM',
        optionA: 'f(x) = (x + 2)(x - 3)',
        optionB: 'f(x) = 2(x + 2)(x - 3)',
        optionC: 'f(x) = -(x + 2)(x - 3)',
        optionD: 'f(x) = (x - 2)(x + 3)',
        optionE: 'f(x) = 0,5(x + 2)(x - 3)',
        correctOption: 'E',
        explanation:
            'As raizes indicam os fatores (x + 2) e (x - 3). Substituindo o vertice x = 0,5 e y = -6,25, encontramos a = 0,5.',
      ),
      Question(
        text:
            'Em um texto dissertativo, qual estrategia melhora a coesao entre paragrafos?',
        subject: 'Portugues',
        topic: 'Interpretacao de Texto',
        difficulty: 1,
        year: 2022,
        examSource: 'FUVEST',
        optionA: 'Repetir sempre o mesmo conectivo',
        optionB: 'Usar operadores argumentativos adequados',
        optionC: 'Eliminar todos os pronomes',
        optionD: 'Evitar retomadas de ideias',
        optionE: null,
        correctOption: 'B',
        explanation:
            'Operadores argumentativos conectam ideias e deixam clara a relacao logica entre argumentos.',
      ),
      Question(
        text:
            'Um carro percorre 120 km em 2 horas. Qual e sua velocidade media?',
        subject: 'Fisica',
        topic: 'Cinematica',
        difficulty: 1,
        year: 2023,
        examSource: 'UFSC',
        optionA: '30 km/h',
        optionB: '45 km/h',
        optionC: '60 km/h',
        optionD: '90 km/h',
        optionE: null,
        correctOption: 'C',
        explanation:
            'A velocidade media e dada por distancia dividida pelo tempo: 120 / 2 = 60 km/h.',
      ),
      Question(
        text:
            'A queima completa de hidrocarbonetos produz majoritariamente quais substancias?',
        subject: 'Quimica',
        topic: 'Estequiometria',
        difficulty: 2,
        year: 2022,
        examSource: 'ENEM',
        optionA: 'CO2 e H2O',
        optionB: 'CO e H2',
        optionC: 'O2 e N2',
        optionD: 'CH4 e NH3',
        optionE: 'H2 e O3',
        correctOption: 'A',
        explanation:
            'Na combustao completa, o carbono forma CO2 e o hidrogenio forma H2O.',
      ),
      Question(
        text:
            'Qual processo biologico explica a transmissao das caracteristicas hereditarias?',
        subject: 'Biologia',
        topic: 'Genetica Mendeliana',
        difficulty: 2,
        year: 2021,
        examSource: 'UNICAMP',
        optionA: 'Fermentacao',
        optionB: 'Segregacao dos alelos',
        optionC: 'Fotossintese',
        optionD: 'Osmose',
        optionE: null,
        correctOption: 'B',
        explanation:
            'A genetica mendeliana descreve como alelos se segregam e sao transmitidos aos descendentes.',
      ),
    ];
  }

  List<String>? _expandSubjectAliases(List<String>? subjects) {
    // Bloco 35 - sem filtro de materia, devolve exatamente o valor recebido.
    if (subjects == null || subjects.isEmpty) return subjects;

    // Bloco 36 - Set evita duplicar a mesma materia/alias.
    final aliases = <String>{};
    for (final subject in subjects) {
      // Bloco 37 - sempre preserva o texto original escolhido na UI.
      aliases.add(subject);
      switch (_normalize(subject)) {
        case 'matematica':
          aliases.addAll(const ['Matematica', 'Matemática', 'MatemÃ¡tica']);
          break;
        case 'linguagens':
        case 'portugues':
          aliases.addAll(const ['Linguagens', 'Portugues', 'Português']);
          break;
        case 'historia':
          aliases.addAll(const ['Historia', 'História', 'HistÃ³ria']);
          break;
        case 'quimica':
          aliases.addAll(const ['Quimica', 'Química', 'QuÃ­mica']);
          break;
        case 'fisica':
          aliases.addAll(const ['Fisica', 'Física']);
          break;
        case 'ciencias humanas':
          aliases.addAll(const [
            'Ciencias Humanas',
            'Ciências Humanas',
            'Historia',
            'História',
            'Geografia',
            'Filosofia',
            'Sociologia',
          ]);
          break;
        case 'ciencias':
        case 'natureza':
        case 'ciencias da natureza':
          aliases.addAll(const [
            'Ciencias',
            'Ciências',
            'Ciencias da Natureza',
            'Ciências da Natureza',
            'Biologia',
            'Quimica',
            'Química',
            'QuÃ­mica',
            'Fisica',
            'Física',
          ]);
          break;
        default:
          break;
      }
    }

    return aliases.toList(growable: false);
  }

  String _normalize(String value) {
    // Bloco 38 - normalizacao simples para comparar filtros.
    // Mantem compatibilidade com alguns textos importados com encoding antigo.
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  String _questionContentKey(Question question) {
    // Bloco 39 - chave de deduplicacao baseada no conteudo da questao.
    return QuestionQualityPolicy.contentKey(question);
  }

  List<int> _parseImportedYears(String? rawValue) {
    // Bloco 40 - transforma "2025,2024,2023" em [2025, 2024, 2023].
    if (rawValue == null || rawValue.trim().isEmpty) {
      return const <int>[];
    }

    return rawValue
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .toList(growable: false);
  }
}
