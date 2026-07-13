import 'package:flutter/foundation.dart';

import '../../domain/entities/attempt.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/ensure_local_enem_bank.dart';
import '../../domain/usecases/get_questions_by_filter.dart';
import '../../domain/usecases/get_wrong_questions.dart';
import '../../domain/usecases/save_attempt.dart';
import '../../domain/usecases/toggle_favorite_question.dart';

enum QuestionAnswerStatus {
  // Bloco 1 - nenhum clique feito ainda.
  idle,

  // Bloco 2 - usuario escolheu alternativa, mas ainda nao confirmou.
  selected,

  // Bloco 3 - resposta confirmada e feedback liberado.
  answered,
}

class AnswerFeedback {
  // Bloco 4 - objeto usado pela tela de feedback.
  // Ele concentra tudo que a tela precisa mostrar depois da resposta.
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
  // Bloco 5 - construtor recebe os casos de uso da camada de dominio.
  // O Provider nao sabe como o banco funciona; ele apenas chama use cases.
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

  // Bloco 6 - dependencias do Provider.
  // Cada dependencia representa uma acao de negocio.
  final EnsureLocalEnemBank _ensureLocalEnemBank;
  final GetQuestionsByFilter _getQuestionsByFilter;
  final GetWrongQuestions _getWrongQuestions;
  final ToggleFavoriteQuestion _toggleFavoriteQuestion;
  final SaveAttempt _saveAttempt;

  // Bloco 7 - filtros escolhidos pelo usuario.
  final Set<String> _selectedSubjects = <String>{};
  final Set<int> _selectedDifficulties = <int>{};

  // Bloco 8 - controla favoritos que estao sendo atualizados.
  // Evita travar ou disparar dois updates ao clicar varias vezes rapido.
  final Set<int> _favoriteUpdatesInFlight = <int>{};

  // Bloco 9 - limite padrao para a lista nao carregar milhares de questoes.
  static const int _defaultQuestionLimit = 120;

  // Bloco 10 - listas de questoes usadas em telas diferentes.
  List<Question> _questions = <Question>[];
  List<Question> _wrongQuestions = <Question>[];
  List<Question> _favoriteQuestions = <Question>[];
  List<Question> _recommendedQuestions = <Question>[];

  // Bloco 11 - estado da resposta atual.
  QuestionAnswerStatus _answerStatus = QuestionAnswerStatus.idle;
  AnswerFeedback? _lastFeedback;
  String? _selectedOption;

  // Bloco 12 - estados de filtro/carregamento.
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

  // Bloco 13 - guarda futures em andamento para evitar chamadas duplicadas.
  Future<void>? _localBankInitialization;
  Future<void>? _questionsLoadOperation;

  // Bloco 14 - getters publicos para as telas.
  // List.unmodifiable impede a UI de alterar listas diretamente.
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

  // Bloco 15 - a tela usa isso para desabilitar o botao de favorito.
  bool isFavoriteUpdating(int? questionId) {
    return questionId != null && _favoriteUpdatesInFlight.contains(questionId);
  }

  // Bloco 16 - questao atual exibida na tela de resposta.
  Question? get currentQuestion {
    if (_questions.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _questions.length) return null;
    return _questions[_currentIndex];
  }

  // Bloco 17 - progresso usado no LinearProgressIndicator.
  double get progress {
    if (_questions.isEmpty) return 0;
    return ((_currentIndex + 1) / _questions.length).clamp(0, 1).toDouble();
  }

  // Bloco 18 - define se o botao confirmar resposta pode ficar ativo.
  bool get canConfirmAnswer {
    return _selectedOption != null &&
        _answerStatus == QuestionAnswerStatus.selected &&
        !_isSavingAnswer;
  }

  // Bloco 19 - define se ja pode ir para a proxima questao.
  bool get canGoToNextQuestion {
    return _answerStatus == QuestionAnswerStatus.answered;
  }

  // Bloco 20 - entrada publica para carregar questoes.
  // Protege contra recarregamento duplicado e contra importacao em andamento.
  Future<void> loadQuestions({int? limit}) {
    if (_isSyncingEnem) return Future<void>.value();
    if (_questionsLoadOperation != null) return _questionsLoadOperation!;

    _questionsLoadOperation = _loadQuestions(limit: limit).whenComplete(() {
      _questionsLoadOperation = null;
    });
    return _questionsLoadOperation!;
  }

  // Bloco 21 - busca questoes no repositorio aplicando filtros atuais.
  Future<void> _loadQuestions({int? limit}) async {
    // Bloco 21.1 - liga estado de loading e limpa erro anterior.
    _setLoading(true);
    _errorMessage = null;

    try {
      // Bloco 21.2 - chama use case passando filtros da tela.
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

      // Bloco 21.3 - se o indice atual ficou fora da nova lista, volta ao inicio.
      if (_currentIndex >= _questions.length) _currentIndex = 0;

      // Bloco 21.4 - ao trocar lista/filtro, limpa alternativa e feedback.
      _clearAnswerState();
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar as questoes.';
    } finally {
      // Bloco 21.5 - desliga loading e notifica a UI.
      _setLoading(false);
    }
  }

  // Bloco 22 - garante que os JSONs locais do ENEM foram importados.
  Future<void> initializeLocalEnemBank() {
    if (_localBankReady) return Future<void>.value();
    return _localBankInitialization ??= _prepareLocalEnemBank().whenComplete(
      () => _localBankInitialization = null,
    );
  }

  // Bloco 23 - rotina real de preparacao do banco ENEM offline.
  Future<void> _prepareLocalEnemBank() async {
    // Bloco 23.1 - marca a tela como carregando/importando.
    _isLoading = true;
    _isSyncingEnem = true;
    _errorMessage = null;
    _syncMessage = 'Preparando banco local do ENEM...';
    notifyListeners();

    try {
      // Bloco 23.2 - chama use case que importa JSON local para SQLite.
      final result = await _ensureLocalEnemBank();

      // Bloco 23.3 - atualiza mensagens de status.
      _localBankReady = true;
      _syncMessage = result.didImport
          ? 'Banco ENEM local pronto: ${result.saved} questoes salvas.'
          : 'Banco ENEM local pronto: ${result.totalFetched} questoes no SQLite.';

      // Bloco 23.4 - carrega primeiras questoes para a tela inicial.
      _questions = await _getQuestionsByFilter(limit: 80);
      _currentIndex = 0;
      _clearAnswerState();
    } catch (error) {
      // Bloco 23.5 - se a importacao falhar, tenta ao menos carregar cache local.
      _errorMessage = 'Nao foi possivel preparar o banco local do ENEM.';
      _syncMessage = 'Falha ao carregar JSON local do ENEM: $error';
      try {
        _questions = await _getQuestionsByFilter(limit: 80);
      } catch (_) {
        _questions = <Question>[];
      }
    } finally {
      // Bloco 23.6 - encerra estado de importacao.
      _isLoading = false;
      _isSyncingEnem = false;
      notifyListeners();
    }
  }

  // Bloco 24 - carrega questoes erradas para revisao.
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

  // Bloco 25 - carrega as tres listas usadas na revisao inteligente.
  Future<void> loadReviewQuestions(int userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Bloco 25.1 - busca erradas, favoritas e recomendadas em paralelo.
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

  // Bloco 26 - seleciona uma questao aberta pela lista.
  void selectQuestion(Question question) {
    // Bloco 26.1 - procura a questao na lista atual.
    final index = _questions.indexWhere((item) => item.id == question.id);
    if (index < 0) {
      // Bloco 26.2 - se veio de outra tela, coloca no inicio da lista.
      _questions = [
        question,
        ..._questions.where((item) => item.id != question.id),
      ];
      _currentIndex = 0;
    } else {
      // Bloco 26.3 - se ja existe na lista, apenas move o indice.
      _currentIndex = index;
    }

    // Bloco 26.4 - limpa resposta anterior e atualiza UI.
    _clearAnswerState();
    notifyListeners();
  }

  // Bloco 27 - substitui a lista por questoes de um simulado.
  void replaceQuestionSet(List<Question> questions) {
    _questions = List<Question>.from(questions);
    _currentIndex = 0;
    _clearAnswerState();
    notifyListeners();
  }

  // Bloco 28 - usuario escolhe uma alternativa.
  void selectAlternative(String option) {
    // Bloco 28.1 - depois de respondida, nao deixa trocar alternativa.
    if (_answerStatus == QuestionAnswerStatus.answered) return;

    // Bloco 28.2 - normaliza para A/B/C/D/E e marca como selecionada.
    _selectedOption = Question.normalizeOption(option);
    _answerStatus = QuestionAnswerStatus.selected;
    notifyListeners();
  }

  // Bloco 29 - confirma resposta no modo treino livre.
  Future<AnswerFeedback?> confirmSelectedAnswer({
    required int userId,
    String sessionId = 'free-practice',
    int timeTakenSeconds = 0,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    // Bloco 29.1 - captura questao, id e alternativa atuais.
    final question = currentQuestion;
    final questionId = question?.id;
    final selectedOption = _selectedOption;

    // Bloco 29.2 - valida se existe uma questao e uma alternativa selecionada.
    if (question == null || questionId == null || selectedOption == null) {
      _errorMessage = 'Selecione uma alternativa antes de confirmar.';
      notifyListeners();
      return null;
    }

    // Bloco 29.3 - liga estado de salvamento para desabilitar botao.
    _isSavingAnswer = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Bloco 29.4 - corrige comparando alternativa escolhida com gabarito.
      final isCorrect = question.isCorrectAnswer(selectedOption);

      // Bloco 29.5 - cria tentativa que sera persistida no SQLite.
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

      // Bloco 29.6 - salva tentativa; o banco atualiza estatisticas/progresso.
      await _saveAttempt(attempt);

      // Bloco 29.7 - prepara dados da tela de feedback.
      _lastFeedback = AnswerFeedback(
        question: question,
        selectedOption: selectedOption,
        correctOption: question.normalizedCorrectOption,
        isCorrect: isCorrect,
        explanation: question.feedback,
        xpEarned: isCorrect ? 15 : 0,
      );

      // Bloco 29.8 - marca como respondida.
      _answerStatus = QuestionAnswerStatus.answered;
      return _lastFeedback;
    } catch (_) {
      _errorMessage = 'Nao foi possivel salvar a resposta.';
      return null;
    } finally {
      // Bloco 29.9 - desliga salvamento e avisa a UI.
      _isSavingAnswer = false;
      notifyListeners();
    }
  }

  // Bloco 30 - registra feedback quando a resposta veio do SessionProvider.
  // Isso e usado no simulado, onde a tentativa e salva pelo provider de sessao.
  AnswerFeedback? registerAnsweredFeedback({
    required Question question,
    required String selectedOption,
    required bool isCorrect,
  }) {
    // Bloco 30.1 - normaliza alternativa selecionada.
    _selectedOption = Question.normalizeOption(selectedOption);

    // Bloco 30.2 - recalcula acerto pela questao exibida para evitar dessincronia.
    final actualIsCorrect = question.isCorrectAnswer(_selectedOption!);
    final feedbackIsCorrect =
        isCorrect == actualIsCorrect ? isCorrect : actualIsCorrect;

    // Bloco 30.3 - monta feedback final.
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

  // Bloco 31 - avanca para a proxima questao da lista.
  void nextQuestion() {
    if (_questions.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _questions.length;
    _clearAnswerState();
    notifyListeners();
  }

  // Bloco 32 - atualiza texto de busca e recarrega questoes.
  Future<void> setSearchText(String value) async {
    _searchText = value.trim();
    notifyListeners();
    await loadQuestions();
  }

  // Bloco 33 - aplica filtro unico de materia vindo da tela.
  Future<void> setSingleSubjectFilter(String? subject) async {
    _selectedSubjects.clear();
    if (subject != null && subject.isNotEmpty && subject != 'Todas') {
      _selectedSubjects.add(subject);
    }
    notifyListeners();
    await loadQuestions();
  }

  // Bloco 34 - aplica filtro de ano especifico do ENEM.
  Future<void> setExamYearFilter(int? year) async {
    _selectedExamYear = year;
    notifyListeners();
    await loadQuestions();
  }

  // Bloco 35 - alterna uma materia no conjunto de filtros.
  Future<void> toggleSubject(String subject) async {
    if (_selectedSubjects.contains(subject)) {
      _selectedSubjects.remove(subject);
    } else {
      _selectedSubjects.add(subject);
    }
    notifyListeners();
    await loadQuestions();
  }

  // Bloco 36 - alterna uma dificuldade no conjunto de filtros.
  Future<void> toggleDifficulty(int difficulty) async {
    if (_selectedDifficulties.contains(difficulty)) {
      _selectedDifficulties.remove(difficulty);
    } else {
      _selectedDifficulties.add(difficulty);
    }
    notifyListeners();
    await loadQuestions();
  }

  // Bloco 37 - liga/desliga filtro de favoritas.
  Future<void> toggleFavoritesOnly() async {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
    await loadQuestions();
  }

  // Bloco 38 - favorita/desfavorita uma questao sem travar a tela.
  Future<void> toggleFavorite(Question question) async {
    // Bloco 38.1 - sem id nao da para atualizar no banco.
    final questionId = question.id;
    if (questionId == null) return;
    if (_favoriteUpdatesInFlight.contains(questionId)) return;

    // Bloco 38.2 - guarda estado anterior para rollback se o banco falhar.
    final nextValue = !question.isFavorite;
    final previousQuestions = List<Question>.from(_questions);
    final previousWrongQuestions = List<Question>.from(_wrongQuestions);
    final previousFavoriteQuestions = List<Question>.from(_favoriteQuestions);
    final previousRecommendedQuestions =
        List<Question>.from(_recommendedQuestions);
    final previousCurrentIndex = _currentIndex;

    // Bloco 38.3 - aplica atualizacao otimista na UI.
    _favoriteUpdatesInFlight.add(questionId);
    _applyFavoriteState(questionId: questionId, isFavorite: nextValue);
    _errorMessage = null;
    notifyListeners();

    try {
      // Bloco 38.4 - grava favorito no SQLite.
      final updatedRows = await _toggleFavoriteQuestion(
        questionId: questionId,
        isFavorite: nextValue,
      );
      if (updatedRows == 0) {
        throw StateError('Questao nao encontrada.');
      }
    } catch (_) {
      // Bloco 38.5 - se falhar, restaura tudo que estava antes.
      _questions = previousQuestions;
      _wrongQuestions = previousWrongQuestions;
      _favoriteQuestions = previousFavoriteQuestions;
      _recommendedQuestions = previousRecommendedQuestions;
      _currentIndex = previousCurrentIndex;
      _errorMessage = 'Nao foi possivel atualizar o favorito.';
    } finally {
      // Bloco 38.6 - libera o botao de favorito novamente.
      _favoriteUpdatesInFlight.remove(questionId);
      notifyListeners();
    }
  }

  // Bloco 39 - aplica estado favorito nas listas em memoria.
  void _applyFavoriteState({
    required int questionId,
    required bool isFavorite,
  }) {
    // Bloco 39.1 - funcao local para atualizar uma lista de questoes.
    List<Question> updateList(List<Question> source) {
      final updated = <Question>[];
      for (final item in source) {
        // Bloco 39.2 - questoes diferentes seguem iguais.
        if (item.id != questionId) {
          updated.add(item);
          continue;
        }

        // Bloco 39.3 - se filtro favoritas esta ativo e desfavoritou, remove.
        if (_favoritesOnly && !isFavorite) {
          continue;
        }

        // Bloco 39.4 - troca apenas o campo isFavorite.
        updated.add(item.copyWith(isFavorite: isFavorite));
      }
      return updated;
    }

    // Bloco 39.5 - atualiza listas principais.
    _questions = updateList(_questions);
    _wrongQuestions = updateList(_wrongQuestions);
    _recommendedQuestions = updateList(_recommendedQuestions);

    if (isFavorite) {
      // Bloco 39.6 - se ja estava na lista de favoritas, atualiza item.
      final existingIndex = _favoriteQuestions.indexWhere(
        (item) => item.id == questionId,
      );
      if (existingIndex >= 0) {
        _favoriteQuestions = List<Question>.from(_favoriteQuestions)
          ..[existingIndex] =
              _favoriteQuestions[existingIndex].copyWith(isFavorite: true);
      }
    } else {
      // Bloco 39.7 - se desfavoritou, remove da lista de favoritas.
      _favoriteQuestions = _favoriteQuestions
          .where((item) => item.id != questionId)
          .toList(growable: false);
    }

    // Bloco 39.8 - garante indice valido depois de remover itens.
    if (_currentIndex >= _questions.length) {
      _currentIndex = _questions.isEmpty ? 0 : _questions.length - 1;
    }
  }

  // Bloco 40 - limpa todos os filtros.
  void clearFilters() {
    _selectedSubjects.clear();
    _selectedDifficulties.clear();
    _selectedExamYear = null;
    _favoritesOnly = false;
    _searchText = '';
    notifyListeners();
  }

  // Bloco 41 - limpa erro atual.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Bloco 42 - limpa estado de resposta da questao atual.
  void _clearAnswerState() {
    _selectedOption = null;
    _lastFeedback = null;
    _answerStatus = QuestionAnswerStatus.idle;
  }

  // Bloco 43 - liga/desliga loading evitando notify desnecessario.
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
