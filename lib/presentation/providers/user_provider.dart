import 'package:flutter/foundation.dart';

import '../../domain/entities/study_progress.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_or_create_user.dart';
import '../../domain/usecases/get_study_progress.dart';
import '../../domain/usecases/get_user_statistics.dart';
import '../../domain/usecases/set_weekly_goal.dart';
import '../../domain/usecases/update_user_avatar.dart';
import '../../domain/usecases/update_user_name.dart';

class UserProvider extends ChangeNotifier {
  // Bloco 1 - construtor recebe todos os casos de uso que mexem com usuario.
  // O Provider nao acessa banco diretamente; ele chama use cases do dominio.
  UserProvider({
    required GetOrCreateUser getOrCreateUser,
    required GetUserStatistics getUserStatistics,
    required GetStudyProgress getStudyProgress,
    required SetWeeklyGoal setWeeklyGoal,
    required UpdateUserAvatar updateUserAvatar,
    required UpdateUserName updateUserName,
  })  : _getOrCreateUser = getOrCreateUser,
        _getUserStatistics = getUserStatistics,
        _getStudyProgress = getStudyProgress,
        _setWeeklyGoal = setWeeklyGoal,
        _updateUserAvatar = updateUserAvatar,
        _updateUserName = updateUserName;

  // Bloco 2 - dependencias vindas da camada de dominio.
  // Cada uma representa uma acao: buscar usuario, estatisticas, meta, avatar etc.
  final GetOrCreateUser _getOrCreateUser;
  final GetUserStatistics _getUserStatistics;
  final GetStudyProgress _getStudyProgress;
  final SetWeeklyGoal _setWeeklyGoal;
  final UpdateUserAvatar _updateUserAvatar;
  final UpdateUserName _updateUserName;

  // Bloco 3 - estado interno do Provider.
  // Essas variaveis guardam os dados reais usados pelas telas.
  User? _user;
  UserStatistics? _statistics;
  StudyProgress? _progress;
  bool _isLoading = false;

  // Bloco 4 - versao visual do avatar.
  // Quando troca/remove foto, esse numero muda para forcar a tela a redesenhar.
  int _avatarVersion = 0;
  String? _errorMessage;

  // Bloco 5 - getters publicos.
  // As telas leem esses valores, mas nao alteram o estado diretamente.
  User? get user => _user;
  UserStatistics? get statistics => _statistics;
  StudyProgress? get progress => _progress;
  bool get isLoading => _isLoading;
  int get avatarVersion => _avatarVersion;
  String? get errorMessage => _errorMessage;

  int get userId => _user?.id ?? 1;
  double get accuracyRate => _statistics?.accuracyRate ?? 0;
  int get totalAnswered => _statistics?.totalAnswered ?? 0;
  int get totalCorrect => _statistics?.totalCorrect ?? 0;
  int get currentStreak => _progress?.currentStreak ?? 0;
  int get maxStreak => _progress?.maxStreak ?? 0;
  int get weeklyGoalQuestions => _progress?.weeklyGoalQuestions ?? 50;
  int get weeklyAnsweredQuestions => _progress?.weeklyAnsweredQuestions ?? 0;
  int get remainingWeeklyQuestions =>
      _progress?.remainingWeeklyQuestions ?? weeklyGoalQuestions;
  double get weeklyGoalProgress => _progress?.weeklyProgressRate ?? 0;

  // Bloco 6 - carrega usuario, estatisticas e progresso.
  // Pode receber userId para garantir que vamos recarregar o usuario certo.
  Future<void> loadUser({int? userId}) async {
    // Bloco 6.1 - liga estado de carregamento e limpa erro antigo.
    _setLoading(true);
    _errorMessage = null;

    try {
      // Bloco 6.2 - guarda avatar anterior para saber se precisa redesenhar.
      final previousAvatar = _user?.avatar;

      // Bloco 6.3 - escolhe o usuario preferencial.
      // Se userId veio de fora, usa ele; senao usa o id ja carregado.
      final preferredUserId = userId ?? _user?.id;

      // Bloco 6.4 - busca usuario existente ou cria um padrao.
      _user = await _getOrCreateUser(userId: preferredUserId);

      // Bloco 6.5 - se avatar mudou no banco, incrementa versao visual.
      if (previousAvatar != _user?.avatar) {
        _avatarVersion++;
      }

      // Bloco 6.6 - carrega estatisticas do usuario encontrado.
      final resolvedUserId = userId ?? _user?.id;
      if (resolvedUserId != null) {
        _statistics = await _getUserStatistics(resolvedUserId);
      }

      // Bloco 6.7 - carrega streak, meta semanal e progresso.
      _progress = await _getStudyProgress();
    } catch (_) {
      // Bloco 6.8 - qualquer erro vira mensagem simples para a UI.
      _errorMessage = 'Nao foi possivel carregar o perfil.';
    } finally {
      // Bloco 6.9 - desliga carregamento e notifica as telas.
      _setLoading(false);
    }
  }

  // Bloco 7 - apelido para recarregar o perfil.
  // Mantem a chamada nas telas mais legivel.
  Future<void> refresh({int? userId}) {
    return loadUser(userId: userId);
  }

  // Bloco 8 - atualiza a meta semanal de questoes.
  Future<void> updateWeeklyGoal(int value) async {
    try {
      // Bloco 8.1 - salva nova meta e recebe progresso atualizado.
      _progress = await _setWeeklyGoal(value);
      notifyListeners();
    } catch (_) {
      // Bloco 8.2 - erro fica salvo para a tela exibir se quiser.
      _errorMessage = 'Nao foi possivel atualizar a meta semanal.';
      notifyListeners();
    }
  }

  // Bloco 9 - altera o nome do usuario local.
  Future<void> updateName(String name) async {
    // Bloco 9.1 - garante que existe usuario carregado.
    final user = _user;
    if (user?.id == null) {
      throw StateError('Perfil local nao encontrado.');
    }

    // Bloco 9.2 - salva nome pelo use case e atualiza apenas o nome na memoria.
    final updatedName = await _updateUserName(userId: user!.id!, name: name);
    _user = user.copyWith(name: updatedName);
    _errorMessage = null;
    notifyListeners();
  }

  // Bloco 10 - salva uma nova foto de perfil.
  // avatarPath aqui pode ser um data:image/...;base64, nao um caminho fisico.
  Future<void> updateAvatar(String avatarPath) async {
    // Bloco 10.1 - sem usuario carregado nao sabemos qual linha atualizar.
    final user = _user;
    if (user?.id == null) {
      throw StateError('Perfil local nao encontrado.');
    }

    // Bloco 10.2 - chama o use case, que salva no SQLite e recarrega o usuario.
    final updatedUser = await _updateUserAvatar(
      userId: user!.id!,
      avatarPath: avatarPath,
    );

    // Bloco 10.3 - substitui o usuario em memoria pelo usuario real do banco.
    _user = updatedUser;

    // Bloco 10.4 - forca a UI a reconstruir o widget da imagem.
    _avatarVersion++;
    _errorMessage = null;
    notifyListeners();
  }

  // Bloco 11 - remove a foto de perfil.
  Future<void> clearAvatar() async {
    // Bloco 11.1 - valida usuario carregado.
    final user = _user;
    if (user?.id == null) {
      throw StateError('Perfil local nao encontrado.');
    }

    // Bloco 11.2 - salva null no avatar e recarrega usuario do SQLite.
    _user = await _updateUserAvatar(userId: user!.id!, avatarPath: null);

    // Bloco 11.3 - muda versao para a tela voltar para as iniciais.
    _avatarVersion++;
    _errorMessage = null;
    notifyListeners();
  }

  // Bloco 12 - limpa mensagem de erro manualmente.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Bloco 13 - helper para ligar/desligar carregamento.
  // Sempre notifica as telas quando muda.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
