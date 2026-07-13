import 'package:flutter/foundation.dart';

import '../../domain/entities/attempt.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/usecases/generate_simulado.dart';
import '../../domain/usecases/get_recent_simulados.dart';
import '../../domain/usecases/save_attempt.dart';
import '../../domain/usecases/save_study_session.dart';

enum SessionStatus {
  // Bloco 1 - usuario ainda esta escolhendo materias e quantidade.
  configuring,

  // Bloco 2 - simulado comecou e esta respondendo questoes.
  inProgress,

  // Bloco 3 - simulado terminou e resultado foi salvo.
  finished,
}

class SessionProvider extends ChangeNotifier {
  // Bloco 4 - construtor recebe use cases necessarios para simulado.
  SessionProvider({
    required GenerateSimulado generateSimulado,
    required SaveAttempt saveAttempt,
    required SaveStudySession saveStudySession,
    required GetRecentSimulados getRecentSimulados,
  })  : _generateSimulado = generateSimulado,
        _saveAttempt = saveAttempt,
        _saveStudySession = saveStudySession,
        _getRecentSimulados = getRecentSimulados;

  // Bloco 5 - use cases usados pelo provider.
  final GenerateSimulado _generateSimulado;
  final SaveAttempt _saveAttempt;
  final SaveStudySession _saveStudySession;
  final GetRecentSimulados _getRecentSimulados;

  // Bloco 6 - materias selecionadas na tela de configuracao.
  final Set<String> _selectedSubjects = <String>{'Matematica', 'Portugues'};

  // Bloco 7 - tentativas feitas durante o simulado atual.
  final List<Attempt> _attempts = <Attempt>[];

  // Bloco 8 - estado principal do simulado.
  List<Question> _sessionQuestions = <Question>[];
  List<StudySession> _recentSimulados = <StudySession>[];
  SessionStatus _status = SessionStatus.configuring;
  int _questionQuantity = 30;
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _sessionId;
  String? _errorMessage;
  DateTime? _startedAt;

  // Bloco 9 - getters usados pelas telas.
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
  String? get errorMessage => _errorMessage;

  // Bloco 10 - total de acertos calculado pelas tentativas.
  int get correctCount =>
      _attempts.where((attempt) => attempt.isCorrect).length;

  // Bloco 11 - total de erros.
  int get wrongCount => _attempts.length - correctCount;

  // Bloco 12 - taxa de acerto em decimal, de 0 a 1.
  double get scoreRate {
    if (_attempts.isEmpty) return 0;
    return correctCount / _attempts.length;
  }

  // Bloco 13 - taxa de acerto em porcentagem inteira.
  int get scorePercentage => (scoreRate * 100).round();

  // Bloco 14 - progresso visual do simulado atual.
  double get progress {
    if (_sessionQuestions.isEmpty) return 0;
    return ((_currentIndex + 1) / _sessionQuestions.length)
        .clamp(0, 1)
        .toDouble();
  }

  // Bloco 15 - botao iniciar so fica ativo com materia e sem carregamento.
  bool get canStart => _selectedSubjects.isNotEmpty && !_isLoading;

  // Bloco 16 - questao atual do simulado.
  Question? get currentQuestion {
    if (_sessionQuestions.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _sessionQuestions.length) {
      return null;
    }
    return _sessionQuestions[_currentIndex];
  }

  // Bloco 17 - garante que a questao exibida e a mesma que o simulado espera.
  // Isso evita marcar errado por dessincronia entre providers.
  bool isCurrentQuestion(Question? question) {
    final activeQuestion = currentQuestion;
    return question?.id != null && activeQuestion?.id == question?.id;
  }

  // Bloco 18 - inicializa historico de simulados.
  Future<void> initialize({int userId = 1}) {
    return loadRecentSimulados(userId: userId);
  }

  // Bloco 19 - carrega simulados recentes do usuario.
  Future<void> loadRecentSimulados({
    int userId = 1,
    int limit = 5,
  }) async {
    // Bloco 19.1 - liga loading.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Bloco 19.2 - busca historico no repositorio.
      _recentSimulados = await _getRecentSimulados(userId, limit: limit);
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar simulados recentes.';
    } finally {
      // Bloco 19.3 - desliga loading.
      _isLoading = false;
      notifyListeners();
    }
  }

  // Bloco 20 - atualiza quantidade pelo Slider.
  void setQuestionQuantity(double value) {
    _questionQuantity = value.round().clamp(10, 90).toInt();
    notifyListeners();
  }

  // Bloco 21 - alterna materia escolhida por ChoiceChip.
  void toggleSubject(String subject) {
    if (_selectedSubjects.contains(subject)) {
      _selectedSubjects.remove(subject);
    } else {
      _selectedSubjects.add(subject);
    }
    notifyListeners();
  }

  // Bloco 22 - inicia um novo simulado.
  Future<void> startSimulado({int userId = 1}) async {
    // Bloco 22.1 - liga loading e limpa erro.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Bloco 22.2 - gera questoes com base em quantidade e materias.
      final questions = await _generateSimulado(
        quantity: _questionQuantity,
        subjects: _selectedSubjects.toList(),
      );

      // Bloco 22.3 - se nao achou questoes, avisa a tela e nao inicia.
      if (questions.isEmpty) {
        _errorMessage = 'Nenhuma questao encontrada para esse filtro.';
        return;
      }

      // Bloco 22.4 - cria id unico da sessao.
      _sessionId = 'simulado-${DateTime.now().microsecondsSinceEpoch}';

      // Bloco 22.5 - prepara estado inicial do simulado.
      _sessionQuestions = questions;
      _attempts.clear();
      _currentIndex = 0;
      _startedAt = DateTime.now();
      _status = SessionStatus.inProgress;
    } catch (_) {
      _errorMessage = 'Nao foi possivel iniciar o simulado.';
    } finally {
      // Bloco 22.6 - desliga loading e notifica UI.
      _isLoading = false;
      notifyListeners();
    }
  }

  // Bloco 23 - responde a questao atual do simulado.
  Future<bool> answerCurrentQuestion({
    required int userId,
    required String selectedOption,
    int? expectedQuestionId,
    int timeTakenSeconds = 0,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    // Bloco 23.1 - pega questao atual e id da sessao.
    final question = currentQuestion;
    final questionId = question?.id;
    final activeSessionId = _sessionId;

    // Bloco 23.2 - se nao existe questao ou sessao, nao da para salvar.
    if (question == null || questionId == null || activeSessionId == null) {
      _errorMessage = 'Sessao invalida.';
      notifyListeners();
      return false;
    }

    // Bloco 23.3 - trava contra dessincronia.
    // A tela envia o id esperado; se diferente, nao corrige errado.
    if (expectedQuestionId != null && questionId != expectedQuestionId) {
      _errorMessage = 'Questao do simulado fora de sincronia.';
      notifyListeners();
      return false;
    }

    // Bloco 23.4 - monta tentativa com alternativa normalizada e acerto.
    final attempt = Attempt(
      userId: userId,
      questionId: questionId,
      sessionId: activeSessionId,
      selectedOption: Question.normalizeOption(selectedOption),
      isCorrect: question.isCorrectAnswer(selectedOption),
      timeTakenSeconds: timeTakenSeconds,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );

    // Bloco 23.5 - liga estado de salvamento.
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Bloco 23.6 - salva tentativa no SQLite e adiciona na lista local.
      await _saveAttempt(attempt);
      _attempts.add(attempt);

      // Bloco 23.7 - se era a ultima questao, finaliza; senao avanca.
      if (_currentIndex >= _sessionQuestions.length - 1) {
        await finishSession(userId: userId);
      } else {
        _currentIndex++;
      }

      // Bloco 23.8 - retorna se acertou para a tela de feedback.
      return attempt.isCorrect;
    } catch (_) {
      _errorMessage = 'Nao foi possivel salvar a resposta.';
      return false;
    } finally {
      // Bloco 23.9 - desliga salvamento.
      _isSaving = false;
      notifyListeners();
    }
  }

  // Bloco 24 - finaliza e salva o simulado.
  Future<void> finishSession({required int userId}) async {
    // Bloco 24.1 - valida se ha sessao ativa e horario de inicio.
    final activeSessionId = _sessionId;
    final startedAt = _startedAt;
    if (activeSessionId == null || startedAt == null) return;

    // Bloco 24.2 - calcula horario final e cria entidade StudySession.
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

    // Bloco 24.3 - salva simulado e recarrega historico.
    await _saveStudySession(session);
    _status = SessionStatus.finished;
    await loadRecentSimulados(userId: userId);
  }

  // Bloco 25 - limpa simulado atual e volta para configuracao.
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

  // Bloco 26 - limpa mensagem de erro.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
