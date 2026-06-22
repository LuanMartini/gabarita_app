import 'package:flutter/foundation.dart';

import '../../domain/entities/attempt.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/usecases/generate_simulado.dart';
import '../../domain/usecases/get_recent_simulados.dart';
import '../../domain/usecases/save_attempt.dart';
import '../../domain/usecases/save_study_session.dart';

enum SessionStatus {
  configuring,
  inProgress,
  finished,
}

class SessionProvider extends ChangeNotifier {
  SessionProvider({
    required GenerateSimulado generateSimulado,
    required SaveAttempt saveAttempt,
    required SaveStudySession saveStudySession,
    required GetRecentSimulados getRecentSimulados,
  })  : _generateSimulado = generateSimulado,
        _saveAttempt = saveAttempt,
        _saveStudySession = saveStudySession,
        _getRecentSimulados = getRecentSimulados;

  final GenerateSimulado _generateSimulado;
  final SaveAttempt _saveAttempt;
  final SaveStudySession _saveStudySession;
  final GetRecentSimulados _getRecentSimulados;

  final Set<String> _selectedSubjects = <String>{'Matematica', 'Portugues'};
  final List<Attempt> _attempts = <Attempt>[];

  List<Question> _sessionQuestions = <Question>[];
  List<StudySession> _recentSimulados = <StudySession>[];
  SessionStatus _status = SessionStatus.configuring;
  int _questionQuantity = 30;
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _sessionId;
  String? _examSource;
  String? _errorMessage;
  DateTime? _startedAt;

  Set<String> get selectedSubjects => Set.unmodifiable(_selectedSubjects);
  List<Attempt> get attempts => List.unmodifiable(_attempts);
  List<Question> get sessionQuestions => List.unmodifiable(_sessionQuestions);
  List<StudySession> get recentSimulados => List.unmodifiable(_recentSimulados);
  SessionStatus get status => _status;
  int get questionQuantity => _questionQuantity;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get sessionId => _sessionId;
  String? get examSource => _examSource;
  String? get errorMessage => _errorMessage;

  int get correctCount =>
      _attempts.where((attempt) => attempt.isCorrect).length;

  int get wrongCount => _attempts.length - correctCount;

  double get scoreRate {
    if (_attempts.isEmpty) return 0;
    return correctCount / _attempts.length;
  }

  int get scorePercentage => (scoreRate * 100).round();

  double get progress {
    if (_sessionQuestions.isEmpty) return 0;
    return ((_currentIndex + 1) / _sessionQuestions.length)
        .clamp(0, 1)
        .toDouble();
  }

  bool get canStart => _selectedSubjects.isNotEmpty && !_isLoading;

  Question? get currentQuestion {
    if (_sessionQuestions.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _sessionQuestions.length) {
      return null;
    }
    return _sessionQuestions[_currentIndex];
  }

  Future<void> initialize({int userId = 1}) {
    return loadRecentSimulados(userId: userId);
  }

  Future<void> loadRecentSimulados({
    int userId = 1,
    int limit = 5,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recentSimulados = await _getRecentSimulados(userId, limit: limit);
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar simulados recentes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setQuestionQuantity(double value) {
    _questionQuantity = value.round().clamp(10, 90).toInt();
    notifyListeners();
  }

  void setExamSource(String? value) {
    _examSource = value == 'Todos' ? null : value;
    notifyListeners();
  }

  void toggleSubject(String subject) {
    if (_selectedSubjects.contains(subject)) {
      _selectedSubjects.remove(subject);
    } else {
      _selectedSubjects.add(subject);
    }
    notifyListeners();
  }

  Future<void> startSimulado({int userId = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final questions = await _generateSimulado(
        quantity: _questionQuantity,
        subjects: _selectedSubjects.toList(),
        examSource: _examSource,
      );

      if (questions.isEmpty) {
        _errorMessage = 'Nenhuma questao encontrada para esse filtro.';
        return;
      }

      _sessionId = 'simulado-${DateTime.now().microsecondsSinceEpoch}';
      _sessionQuestions = questions;
      _attempts.clear();
      _currentIndex = 0;
      _startedAt = DateTime.now();
      _status = SessionStatus.inProgress;
    } catch (_) {
      _errorMessage = 'Nao foi possivel iniciar o simulado.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> answerCurrentQuestion({
    required int userId,
    required String selectedOption,
    int timeTakenSeconds = 0,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    final question = currentQuestion;
    final questionId = question?.id;
    final activeSessionId = _sessionId;

    if (question == null || questionId == null || activeSessionId == null) {
      _errorMessage = 'Sessao invalida.';
      notifyListeners();
      return false;
    }

    final attempt = Attempt(
      userId: userId,
      questionId: questionId,
      sessionId: activeSessionId,
      selectedOption: selectedOption,
      isCorrect: question.isCorrectAnswer(selectedOption),
      timeTakenSeconds: timeTakenSeconds,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _saveAttempt(attempt);
      _attempts.add(attempt);

      if (_currentIndex >= _sessionQuestions.length - 1) {
        await finishSession(userId: userId);
      } else {
        _currentIndex++;
      }

      return attempt.isCorrect;
    } catch (_) {
      _errorMessage = 'Nao foi possivel salvar a resposta.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> finishSession({required int userId}) async {
    final activeSessionId = _sessionId;
    final startedAt = _startedAt;
    if (activeSessionId == null || startedAt == null) return;

    final finishedAt = DateTime.now();
    final session = StudySession(
      id: activeSessionId,
      userId: userId,
      type: StudySessionType.simulado,
      subjects: _selectedSubjects.toList(growable: false),
      totalQuestions: _attempts.length,
      correctCount: correctCount,
      durationSeconds: finishedAt.difference(startedAt).inSeconds,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );

    await _saveStudySession(session);
    _status = SessionStatus.finished;
    await loadRecentSimulados(userId: userId);
  }

  void resetSession() {
    _sessionId = null;
    _sessionQuestions = <Question>[];
    _attempts.clear();
    _currentIndex = 0;
    _startedAt = null;
    _status = SessionStatus.configuring;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
