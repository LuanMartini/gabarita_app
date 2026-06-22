import '../../domain/entities/question.dart';
import '../../domain/repositories/i_question_repository.dart';
import '../datasources/local/database_helper.dart';

class QuestionRepositoryImpl implements IQuestionRepository {
  QuestionRepositoryImpl([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  @override
  Future<int> insertQuestion(Question question) {
    return _dbHelper.insertQuestion(question);
  }

  @override
  Future<void> seedMockQuestions({bool force = false}) async {
    if (!force) {
      final existing = await _dbHelper.getFilteredQuestions(
        searchText: 'Uma funcao',
        limit: 1,
      );
      if (existing.isNotEmpty) return;
    }

    for (final question in _mockQuestions()) {
      await _dbHelper.insertQuestion(question);
    }
  }

  @override
  Future<List<Question>> getQuestions() async {
    await seedMockQuestions();
    return _dbHelper.getAllQuestions();
  }

  @override
  Future<List<Question>> getAllQuestions() async {
    await seedMockQuestions();
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
    await seedMockQuestions();

    final resolvedSubjects = subjects ??
        (subject != null && subject.isNotEmpty ? <String>[subject] : null);
    final resolvedExamSource = examSource ?? vestibular;

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
  Future<List<Question>> getWrongQuestions(int userId) {
    return _dbHelper.getWrongQuestions(userId);
  }

  @override
  Future<List<Question>> getFavoriteQuestions() {
    return _dbHelper.getFavoriteQuestions();
  }

  @override
  Future<int> toggleFavorite(int questionId, bool isFavorite) {
    return _dbHelper.toggleFavorite(questionId, isFavorite);
  }

  @override
  Future<int> toggleFavoriteQuestion(int questionId, bool isFavorite) {
    return toggleFavorite(questionId, isFavorite);
  }

  @override
  Future<int> getTotalQuestionsCount() async {
    await seedMockQuestions();
    return _dbHelper.getTotalQuestionsCount();
  }

  @override
  Future<Question?> getDailyChallenge(int userId) async {
    await seedMockQuestions();
    return _dbHelper.getDailyChallenge(userId);
  }

  List<Question> _mockQuestions() {
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
        optionE: null,
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
    if (subjects == null || subjects.isEmpty) return subjects;

    final aliases = <String>{};
    for (final subject in subjects) {
      aliases.add(subject);
      switch (_normalize(subject)) {
        case 'matematica':
          aliases.addAll(const ['Matematica', 'Matemática', 'MatemÃ¡tica']);
          break;
        case 'portugues':
          aliases.addAll(const ['Portugues', 'Português', 'PortuguÃªs']);
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
}
