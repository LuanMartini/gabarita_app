import 'package:flutter/foundation.dart';

import '../../domain/entities/attempt.dart';
import '../../domain/entities/enem_exam.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/add_question.dart';
import '../../domain/usecases/get_available_enem_exams.dart';
import '../../domain/usecases/get_questions_by_filter.dart';
import '../../domain/usecases/get_wrong_questions.dart';
import '../../domain/usecases/save_attempt.dart';
import '../../domain/usecases/sync_enem_questions.dart';
import '../../domain/usecases/toggle_favorite_question.dart';

enum QuestionAnswerStatus {
  idle,
  selected,
  answered,
}

class AnswerFeedback {
  const AnswerFeedback({
    required this.question,
    required this.selectedOption,
    required this.correctOption,
    required this.isCorrect,
    required this.explanation,
    required this.xpEarned,
  });

  final Question question;
  final String selectedOption;
  final String correctOption;
  final bool isCorrect;
  final String explanation;
  final int xpEarned;
}

class QuestionsProvider extends ChangeNotifier {
  QuestionsProvider({
    required GetAvailableEnemExams getAvailableEnemExams,
    required GetQuestionsByFilter getQuestionsByFilter,
    required GetWrongQuestions getWrongQuestions,
    required ToggleFavoriteQuestion toggleFavoriteQuestion,
    required SaveAttempt saveAttempt,
    required SyncEnemQuestions syncEnemQuestions,
    required AddQuestion addQuestion,
  })  : _getAvailableEnemExams = getAvailableEnemExams,
        _getQuestionsByFilter = getQuestionsByFilter,
        _getWrongQuestions = getWrongQuestions,
        _toggleFavoriteQuestion = toggleFavoriteQuestion,
        _saveAttempt = saveAttempt,
        _syncEnemQuestions = syncEnemQuestions,
        _addQuestion = addQuestion;

  final GetAvailableEnemExams _getAvailableEnemExams;
  final GetQuestionsByFilter _getQuestionsByFilter;
  final GetWrongQuestions _getWrongQuestions;
  final ToggleFavoriteQuestion _toggleFavoriteQuestion;
  final SaveAttempt _saveAttempt;
  final SyncEnemQuestions _syncEnemQuestions;
  final AddQuestion _addQuestion;

  final Set<String> _selectedSubjects = <String>{};
  final Set<int> _selectedDifficulties = <int>{};

  List<Question> _questions = <Question>[];
  List<Question> _wrongQuestions = <Question>[];
  List<Question> _favoriteQuestions = <Question>[];
  List<Question> _recommendedQuestions = <Question>[];
  List<EnemExam> _availableEnemExams = <EnemExam>[];
  QuestionAnswerStatus _answerStatus = QuestionAnswerStatus.idle;
  AnswerFeedback? _lastFeedback;
  EnemQuestionSyncResult? _lastSyncResult;
  String? _selectedOption;
  bool _favoritesOnly = false;
  bool _isLoading = false;
  bool _isSyncingEnem = false;
  bool _isSavingAnswer = false;
  int _currentIndex = 0;
  int? _selectedEnemYear;
  String _searchText = '';
  String? _examSource;
  String? _errorMessage;
  String? _syncMessage;
  bool _localBankReady = false;

  List<Question> get questions => List.unmodifiable(_questions);
  List<Question> get wrongQuestions => List.unmodifiable(_wrongQuestions);
  List<Question> get favoriteQuestions => List.unmodifiable(_favoriteQuestions);
  List<Question> get recommendedQuestions =>
      List.unmodifiable(_recommendedQuestions);
  List<EnemExam> get availableEnemExams =>
      List.unmodifiable(_availableEnemExams);
  Set<String> get selectedSubjects => Set.unmodifiable(_selectedSubjects);
  Set<int> get selectedDifficulties => Set.unmodifiable(_selectedDifficulties);
  QuestionAnswerStatus get answerStatus => _answerStatus;
  AnswerFeedback? get lastFeedback => _lastFeedback;
  EnemQuestionSyncResult? get lastSyncResult => _lastSyncResult;
  String? get selectedOption => _selectedOption;
  bool get favoritesOnly => _favoritesOnly;
  bool get isLoading => _isLoading;
  bool get isSyncingEnem => _isSyncingEnem;
  bool get isSavingAnswer => _isSavingAnswer;
  int get currentIndex => _currentIndex;
  int? get selectedEnemYear => _selectedEnemYear;
  String get searchText => _searchText;
  String? get examSource => _examSource;
  String? get errorMessage => _errorMessage;
  String? get syncMessage => _syncMessage;
  bool get localBankReady => _localBankReady;

  Question? get currentQuestion {
    if (_questions.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _questions.length) return null;
    return _questions[_currentIndex];
  }

  double get progress {
    if (_questions.isEmpty) return 0;
    return ((_currentIndex + 1) / _questions.length).clamp(0, 1).toDouble();
  }

  bool get canConfirmAnswer {
    return _selectedOption != null &&
        _answerStatus == QuestionAnswerStatus.selected &&
        !_isSavingAnswer;
  }

  bool get canGoToNextQuestion {
    return _answerStatus == QuestionAnswerStatus.answered;
  }

  Future<void> loadQuestions({int? limit}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _questions = await _getQuestionsByFilter(
        subjects: _selectedSubjects.isEmpty ? null : _selectedSubjects.toList(),
        difficulties: _selectedDifficulties.isEmpty
            ? null
            : _selectedDifficulties.toList(),
        examSource: _examSource,
        favoritesOnly: _favoritesOnly,
        searchText: _searchText.isEmpty ? null : _searchText,
        limit: limit,
      );
      if (_currentIndex >= _questions.length) _currentIndex = 0;
      _clearAnswerState();
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar as questoes.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeLocalEnemBank() async {
    if (_localBankReady || _isSyncingEnem) return;

    _isLoading = true;
    _isSyncingEnem = true;
    _errorMessage = null;
    _syncMessage = 'Preparando banco local do ENEM...';
    notifyListeners();

    var imported = 0;
    var updated = 0;
    var fetched = 0;

    try {
      _availableEnemExams = await _getAvailableEnemExams();
      if (_availableEnemExams.isNotEmpty) {
        _selectedEnemYear ??= _availableEnemExams.first.year;
      }

      for (final exam in _availableEnemExams) {
        final result = await _syncEnemQuestions(
          year: exam.year,
          limit: 0,
        );
        imported += result.imported;
        updated += result.updated;
        fetched += result.totalFetched;
      }

      _localBankReady = true;
      _examSource = null;
      _syncMessage = imported + updated > 0
          ? 'Banco ENEM local pronto: ${imported + updated} questoes importadas.'
          : 'Banco ENEM local pronto: $fetched questoes disponiveis.';
      _questions = await _getQuestionsByFilter(limit: 80);
      _currentIndex = 0;
      _clearAnswerState();
    } catch (error) {
      _errorMessage = 'Nao foi possivel preparar o banco local do ENEM.';
      _syncMessage = 'Falha ao carregar JSON local do ENEM: $error';
      try {
        _questions = await _getQuestionsByFilter(limit: 80);
      } catch (_) {
        _questions = <Question>[];
      }
    } finally {
      _isLoading = false;
      _isSyncingEnem = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailableEnemExams() async {
    try {
      _availableEnemExams = await _getAvailableEnemExams();
      if (_availableEnemExams.isNotEmpty) {
        _selectedEnemYear ??= _availableEnemExams.first.year;
      }
    } catch (_) {
      _syncMessage = 'Nao foi possivel carregar o indice local do ENEM.';
    } finally {
      notifyListeners();
    }
  }

  void setSelectedEnemYear(int year) {
    _selectedEnemYear = year;
    notifyListeners();
  }

  Future<void> syncSelectedEnemExam({
    int limit = 0,
    String? language,
  }) async {
    final year = _selectedEnemYear ?? 2025;
    _isSyncingEnem = true;
    _syncMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastSyncResult = await _syncEnemQuestions(
        year: year,
        limit: limit,
        language: language,
      );
      _examSource = 'ENEM $year';
      _syncMessage = _lastSyncResult!.saved == 0
          ? 'ENEM $year ja estava carregado do JSON local.'
          : 'ENEM $year importado do JSON local: ${_lastSyncResult!.saved} questoes salvas.';
      await loadQuestions();
    } catch (error) {
      _syncMessage =
          'Nao foi possivel importar o ENEM $year do JSON local. $error';
    } finally {
      _isSyncingEnem = false;
      notifyListeners();
    }
  }

  Future<int?> addLocalQuestion(Question question) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final questionId = await _addQuestion(question);
      await loadQuestions();
      return questionId;
    } catch (_) {
      _errorMessage = 'Nao foi possivel salvar a questao escaneada.';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWrongQuestions(int userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _wrongQuestions = await _getWrongQuestions(userId);
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar a revisao.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReviewQuestions(int userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final results = await Future.wait<List<Question>>([
        _getWrongQuestions(userId),
        _getQuestionsByFilter(favoritesOnly: true),
        _getQuestionsByFilter(limit: 8),
      ]);
      _wrongQuestions = results[0];
      _favoriteQuestions = results[1];
      _recommendedQuestions = results[2];
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar a revisao inteligente.';
    } finally {
      _setLoading(false);
    }
  }

  void selectQuestion(Question question) {
    final index = _questions.indexWhere((item) => item.id == question.id);
    if (index < 0) {
      _questions = [
        question,
        ..._questions.where((item) => item.id != question.id),
      ];
      _currentIndex = 0;
    } else {
      _currentIndex = index;
    }
    _clearAnswerState();
    notifyListeners();
  }

  void replaceQuestionSet(List<Question> questions) {
    _questions = List<Question>.from(questions);
    _currentIndex = 0;
    _clearAnswerState();
    notifyListeners();
  }

  void selectAlternative(String option) {
    if (_answerStatus == QuestionAnswerStatus.answered) return;
    _selectedOption = option.toUpperCase();
    _answerStatus = QuestionAnswerStatus.selected;
    notifyListeners();
  }

  Future<AnswerFeedback?> confirmSelectedAnswer({
    required int userId,
    String sessionId = 'free-practice',
    int timeTakenSeconds = 0,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    final question = currentQuestion;
    final questionId = question?.id;
    final selectedOption = _selectedOption;

    if (question == null || questionId == null || selectedOption == null) {
      _errorMessage = 'Selecione uma alternativa antes de confirmar.';
      notifyListeners();
      return null;
    }

    _isSavingAnswer = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isCorrect = question.isCorrectAnswer(selectedOption);
      final attempt = Attempt(
        userId: userId,
        questionId: questionId,
        sessionId: sessionId,
        selectedOption: selectedOption,
        isCorrect: isCorrect,
        timeTakenSeconds: timeTakenSeconds,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
      );

      await _saveAttempt(attempt);
      _lastFeedback = AnswerFeedback(
        question: question,
        selectedOption: selectedOption,
        correctOption: question.correctOption.toUpperCase(),
        isCorrect: isCorrect,
        explanation: question.feedback,
        xpEarned: isCorrect ? 15 : 5,
      );
      _answerStatus = QuestionAnswerStatus.answered;
      return _lastFeedback;
    } catch (_) {
      _errorMessage = 'Nao foi possivel salvar a resposta.';
      return null;
    } finally {
      _isSavingAnswer = false;
      notifyListeners();
    }
  }

  AnswerFeedback? registerAnsweredFeedback({
    required Question question,
    required String selectedOption,
    required bool isCorrect,
  }) {
    _selectedOption = selectedOption.toUpperCase();
    _lastFeedback = AnswerFeedback(
      question: question,
      selectedOption: _selectedOption!,
      correctOption: question.correctOption.toUpperCase(),
      isCorrect: isCorrect,
      explanation: question.feedback,
      xpEarned: isCorrect ? 15 : 5,
    );
    _answerStatus = QuestionAnswerStatus.answered;
    notifyListeners();
    return _lastFeedback;
  }

  void nextQuestion() {
    if (_questions.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _questions.length;
    _clearAnswerState();
    notifyListeners();
  }

  Future<void> setSearchText(String value) async {
    _searchText = value.trim();
    notifyListeners();
    await loadQuestions();
  }

  Future<void> setSingleSubjectFilter(String? subject) async {
    _selectedSubjects.clear();
    if (subject != null && subject.isNotEmpty && subject != 'Todas') {
      _selectedSubjects.add(subject);
    }
    notifyListeners();
    await loadQuestions();
  }

  Future<void> toggleSubject(String subject) async {
    if (_selectedSubjects.contains(subject)) {
      _selectedSubjects.remove(subject);
    } else {
      _selectedSubjects.add(subject);
    }
    notifyListeners();
    await loadQuestions();
  }

  Future<void> toggleDifficulty(int difficulty) async {
    if (_selectedDifficulties.contains(difficulty)) {
      _selectedDifficulties.remove(difficulty);
    } else {
      _selectedDifficulties.add(difficulty);
    }
    notifyListeners();
    await loadQuestions();
  }

  Future<void> setExamSource(String? value) async {
    _examSource = value == 'Todos' ? null : value;
    notifyListeners();
    await loadQuestions();
  }

  Future<void> toggleFavoritesOnly() async {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
    await loadQuestions();
  }

  Future<void> toggleFavorite(Question question) async {
    final questionId = question.id;
    if (questionId == null) return;

    try {
      final nextValue = !question.isFavorite;
      await _toggleFavoriteQuestion(
        questionId: questionId,
        isFavorite: nextValue,
      );
      await loadQuestions();
    } catch (_) {
      _errorMessage = 'Nao foi possivel atualizar o favorito.';
      notifyListeners();
    }
  }

  void clearFilters() {
    _selectedSubjects.clear();
    _selectedDifficulties.clear();
    _favoritesOnly = false;
    _examSource = null;
    _searchText = '';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearAnswerState() {
    _selectedOption = null;
    _lastFeedback = null;
    _answerStatus = QuestionAnswerStatus.idle;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
