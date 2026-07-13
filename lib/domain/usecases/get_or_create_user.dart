import '../entities/user.dart';
import '../repositories/i_user_repository.dart';

// Bloco 1 - caso de uso que garante que o app sempre tenha um perfil local.
// Ele procura um usuario existente e, se nao achar, cria o perfil padrao.
class GetOrCreateUser {
  // Bloco 2 - injeta a interface do repositorio.
  // Isso mantem o dominio independente de SQLite.
  GetOrCreateUser(this._userRepository);

  final IUserRepository _userRepository;

  // Bloco 3 - call e chamado pelo UserProvider durante a inicializacao.
  Future<User> call({
    String defaultName = 'Lucas Mendes',
    int? userId,
  }) async {
    // Bloco 4 - se veio um id especifico, tenta carregar esse perfil primeiro.
    if (userId != null) {
      final existingUser = await _userRepository.getUser(userId);
      if (existingUser != null) return existingUser;
    }

    // Bloco 5 - se nao veio id, pega o primeiro perfil salvo no aparelho.
    final existingUser = await _userRepository.getFirstUser();
    if (existingUser != null) return existingUser;

    // Bloco 6 - se nao existe perfil, cria um usuario padrao para teste.
    final user = User(name: defaultName, studyGoalMinutes: 45);

    // Bloco 7 - salva no banco e devolve a copia ja com id gerado.
    final id = await _userRepository.saveUser(user);
    return user.copyWith(id: id);
  }
}
