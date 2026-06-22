import 'package:flutter/foundation.dart';

import '../../domain/entities/attempt.dart';
import '../../domain/entities/question.dart';
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
    required GetQuestionsByFilter getQuestionsByFilter,
    required GetWrongQuestions getWrongQuestions,
    required ToggleFavoriteQuestion toggleFavoriteQuestion,
    required SaveAttempt saveAttempt,
  })  : _getQuestionsByFilter = getQuestionsByFilter,
        _getWrongQuestions = getWrongQuestions,
        _toggleFavoriteQuestion = toggleFavoriteQuestion,
        _saveAttempt = saveAttempt;

  final GetQuestionsByFilter _getQuestionsByFilter;
  final GetWrongQuestions _getWrongQuestions;
  final ToggleFavoriteQuestion _toggleFavoriteQuestion;
  final SaveAttempt _saveAttempt;

  final Set<String> _selectedSubjects = <String>{};
  final Set<int> _selectedDifficulties = <int>{};

  List<Question> _questions = <Question>[];
  List<Question> _wrongQuestions = <Question>[];
  QuestionAnswerStatus _answerStatus = QuestionAnswerStatus.idle;
  AnswerFeedback? _lastFeedback;
  String? _selectedOption;
  bool _favoritesOnly = false;
  bool _isLoading = false;
  bool _isSavingAnswer = false;
  int _currentIndex = 0;
  String _searchText = '';
  String? _examSource;
  String? _errorMessage;

  List<Question> get questions => List.unmodifiable(_questions);
  List<Question> get wrongQuestions => List.unmodifiable(_wrongQuestions);
  Set<String> get selectedSubjects => Set.unmodifiable(_selectedSubjects);
  Set<int> get selectedDifficulties => Set.unmodifiable(_selectedDifficulties);
  QuestionAnswerStatus get answerStatus => _answerStatus;
  AnswerFeedback? get lastFeedback => _lastFeedback;
  String? get selectedOption => _selectedOption;
  bool get favoritesOnly => _favoritesOnly;
  bool get isLoading => _isLoading;
  bool get isSavingAnswer => _isSavingAnswer;
  int get currentIndex => _currentIndex;
  String get searchText => _searchText;
  String? get examSource => _examSource;
  String? get errorMessage => _errorMessage;

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
        subjects:
            _selectedSubjects.isEmpty ? null : _selectedSubjects.toList(),
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

  void selectQuestion(Question question) {
    final index = _questions.indexWhere((item) => item.id == question.id);
    _currentIndex = index < 0 ? 0 : index;
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
