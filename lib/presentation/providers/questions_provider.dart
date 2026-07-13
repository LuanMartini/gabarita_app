import 'package:flutter/foundation.dart';

import '../../domain/entities/attempt.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/ensure_local_enem_bank.dart';
import '../../domain/usecases/get_questions_by_filter.dart';
import '../../domain/usecases/get_wrong_questions.dart';
import '../../domain/usecases/save_attempt.dart';
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
    required EnsureLocalEnemBank ensureLocalEnemBank,
    required GetQuestionsByFilter getQuestionsByFilter,
    required GetWrongQuestions getWrongQuestions,
    required ToggleFavoriteQuestion toggleFavoriteQuestion,
    required SaveAttempt saveAttempt,
  })  : _ensureLocalEnemBank = ensureLocalEnemBank,
        _getQuestionsByFilter = getQuestionsByFilter,
        _getWrongQuestions = getWrongQuestions,
        _toggleFavoriteQuestion = toggleFavoriteQuestion,
        _saveAttempt = saveAttempt;

  final EnsureLocalEnemBank _ensureLocalEnemBank;
  final GetQuestionsByFilter _getQuestionsByFilter;
  final GetWrongQuestions _getWrongQuestions;
  final ToggleFavoriteQuestion _toggleFavoriteQuestion;
  final SaveAttempt _saveAttempt;

  final Set<String> _selectedSubjects = <String>{};
  final Set<int> _selectedDifficulties = <int>{};
  final Set<int> _favoriteUpdatesInFlight = <int>{};
  static const int _defaultQuestionLimit = 120;

  List<Question> _questions = <Question>[];
  List<Question> _wrongQuestions = <Question>[];
  List<Question> _favoriteQuestions = <Question>[];
  List<Question> _recommendedQuestions = <Question>[];
  QuestionAnswerStatus _answerStatus = QuestionAnswerStatus.idle;
  AnswerFeedback? _lastFeedback;
  String? _selectedOption;
  bool _favoritesOnly = false;
  bool _isLoading = false;
  bool _isSyncingEnem = false;
  bool _isSavingAnswer = false;
  int _currentIndex = 0;
  int? _selectedExamYear;
  String _searchText = '';
  String? _errorMessage;
  String? _syncMessage;
  bool _localBankReady = false;
  Future<void>? _localBankInitialization;
  Future<void>? _questionsLoadOperation;

  List<Question> get questions => List.unmodifiable(_questions);
  List<Question> get wrongQuestions => List.unmodifiable(_wrongQuestions);
  List<Question> get favoriteQuestions => List.unmodifiable(_favoriteQuestions);
  List<Question> get recommendedQuestions =>
      List.unmodifiable(_recommendedQuestions);
  Set<String> get selectedSubjects => Set.unmodifiable(_selectedSubjects);
  Set<int> get selectedDifficulties => Set.unmodifiable(_selectedDifficulties);
  QuestionAnswerStatus get answerStatus => _answerStatus;
  AnswerFeedback? get lastFeedback => _lastFeedback;
  String? get selectedOption => _selectedOption;
  bool get favoritesOnly => _favoritesOnly;
  bool get isLoading => _isLoading;
  bool get isSyncingEnem => _isSyncingEnem;
  bool get isSavingAnswer => _isSavingAnswer;
  bool get isBusy => _isLoading || _isSyncingEnem;
  int get currentIndex => _currentIndex;
  int? get selectedExamYear => _selectedExamYear;
  String get searchText => _searchText;
  String? get errorMessage => _errorMessage;
  String? get syncMessage => _syncMessage;
  bool get localBankReady => _localBankReady;

  bool isFavoriteUpdating(int? questionId) {
    return questionId != null && _favoriteUpdatesInFlight.contains(questionId);
  }

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

  Future<void> loadQuestions({int? limit}) {
    if (_isSyncingEnem) return Future<void>.value();
    if (_questionsLoadOperation != null) return _questionsLoadOperation!;

    _questionsLoadOperation = _loadQuestions(limit: limit).whenComplete(() {
      _questionsLoadOperation = null;
    });
    return _questionsLoadOperation!;
  }

  Future<void> _loadQuestions({int? limit}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _questions = await _getQuestionsByFilter(
        subjects: _selectedSubjects.isEmpty ? null : _selectedSubjects.toList(),
        difficulties: _selectedDifficulties.isEmpty
            ? null
            : _selectedDifficulties.toList(),
        favoritesOnly: _favoritesOnly,
        examSource:
            _selectedExamYear == null ? null : 'ENEM $_selectedExamYear',
        searchText: _searchText.isEmpty ? null : _searchText,
        limit: limit ?? _defaultQuestionLimit,
      );
      if (_currentIndex >= _questions.length) _currentIndex = 0;
      _clearAnswerState();
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar as questoes.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeLocalEnemBank() {
    if (_localBankReady) return Future<void>.value();
    return _localBankInitialization ??= _prepareLocalEnemBank().whenComplete(
      () => _localBankInitialization = null,
    );
  }

  Future<void> _prepareLocalEnemBank() async {
    _isLoading = true;
    _isSyncingEnem = true;
    _errorMessage = null;
    _syncMessage = 'Preparando banco local do ENEM...';
    notifyListeners();

    try {
      final result = await _ensureLocalEnemBank();

      _localBankReady = true;
      _syncMessage = result.didImport
          ? 'Banco ENEM local pronto: ${result.saved} questoes salvas.'
          : 'Banco ENEM local pronto: ${result.totalFetched} questoes no SQLite.';
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
    _selectedOption = Question.normalizeOption(option);
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
        correctOption: question.normalizedCorrectOption,
        isCorrect: isCorrect,
        explanation: question.feedback,
        xpEarned: isCorrect ? 15 : 0,
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
    _selectedOption = Question.normalizeOption(selectedOption);
    final actualIsCorrect = question.isCorrectAnswer(_selectedOption!);
    final feedbackIsCorrect =
        isCorrect == actualIsCorrect ? isCorrect : actualIsCorrect;
    _lastFeedback = AnswerFeedback(
      question: question,
      selectedOption: _selectedOption!,
      correctOption: question.normalizedCorrectOption,
      isCorrect: feedbackIsCorrect,
      explanation: question.feedback,
      xpEarned: feedbackIsCorrect ? 15 : 0,
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

  Future<void> setExamYearFilter(int? year) async {
    _selectedExamYear = year;
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

  Future<void> toggleFavoritesOnly() async {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
    await loadQuestions();
  }

  Future<void> toggleFavorite(Question question) async {
    final questionId = question.id;
    if (questionId == null) return;
    if (_favoriteUpdatesInFlight.contains(questionId)) return;

    final nextValue = !question.isFavorite;
    final previousQuestions = List<Question>.from(_questions);
    final previousWrongQuestions = List<Question>.from(_wrongQuestions);
    final previousFavoriteQuestions = List<Question>.from(_favoriteQuestions);
    final previousRecommendedQuestions =
        List<Question>.from(_recommendedQuestions);
    final previousCurrentIndex = _currentIndex;

    _favoriteUpdatesInFlight.add(questionId);
    _applyFavoriteState(questionId: questionId, isFavorite: nextValue);
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedRows = await _toggleFavoriteQuestion(
        questionId: questionId,
        isFavorite: nextValue,
      );
      if (updatedRows == 0) {
        throw StateError('Questao nao encontrada.');
      }
    } catch (_) {
      _questions = previousQuestions;
      _wrongQuestions = previousWrongQuestions;
      _favoriteQuestions = previousFavoriteQuestions;
      _recommendedQuestions = previousRecommendedQuestions;
      _currentIndex = previousCurrentIndex;
      _errorMessage = 'Nao foi possivel atualizar o favorito.';
    } finally {
      _favoriteUpdatesInFlight.remove(questionId);
      notifyListeners();
    }
  }

  void _applyFavoriteState({
    required int questionId,
    required bool isFavorite,
  }) {
    List<Question> updateList(List<Question> source) {
      final updated = <Question>[];
      for (final item in source) {
        if (item.id != questionId) {
          updated.add(item);
          continue;
        }

        if (_favoritesOnly && !isFavorite) {
          continue;
        }

        updated.add(item.copyWith(isFavorite: isFavorite));
      }
      return updated;
    }

    _questions = updateList(_questions);
    _wrongQuestions = updateList(_wrongQuestions);
    _recommendedQuestions = updateList(_recommendedQuestions);

    if (isFavorite) {
      final existingIndex = _favoriteQuestions.indexWhere(
        (item) => item.id == questionId,
      );
      if (existingIndex >= 0) {
        _favoriteQuestions = List<Question>.from(_favoriteQuestions)
          ..[existingIndex] =
              _favoriteQuestions[existingIndex].copyWith(isFavorite: true);
      }
    } else {
      _favoriteQuestions = _favoriteQuestions
          .where((item) => item.id != questionId)
          .toList(growable: false);
    }

    if (_currentIndex >= _questions.length) {
      _currentIndex = _questions.isEmpty ? 0 : _questions.length - 1;
    }
  }

  void clearFilters() {
    _selectedSubjects.clear();
    _selectedDifficulties.clear();
    _selectedExamYear = null;
    _favoritesOnly = false;
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
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
