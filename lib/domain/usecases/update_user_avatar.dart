import '../entities/user.dart';
import '../repositories/i_user_repository.dart';

// Bloco 1 - caso de uso para trocar/remover a foto de perfil.
// A tela nao fala direto com SQLite; ela chama o Provider, o Provider chama
// este caso de uso, e o caso de uso chama o repositorio.
class UpdateUserAvatar {
  // Bloco 2 - recebe a interface do repositorio por injecao de dependencia.
  // Assim a regra de negocio nao depende da implementacao concreta do banco.
  UpdateUserAvatar(this._userRepository);

  final IUserRepository _userRepository;

  // Bloco 3 - metodo call permite usar a classe como uma funcao:
  // await updateUserAvatar(userId: 1, avatarPath: caminhoOuBase64).
  Future<User> call({
    required int userId,
    required String? avatarPath,
  }) async {
    // Bloco 4 - normaliza entrada.
    // String vazia vira null para representar "sem foto" no banco.
    final normalizedPath = avatarPath?.trim();
    final storedPath = normalizedPath == null || normalizedPath.isEmpty
        ? null
        : normalizedPath;

    // Bloco 5 - grava a nova foto no repositorio.
    // O valor pode ser null, um caminho local antigo ou data:image base64.
    final updatedRows = await _userRepository.updateUserAvatar(
      userId: userId,
      avatarPath: storedPath,
    );

    // Bloco 6 - se nenhuma linha foi atualizada, o perfil nao existe.
    // O erro sobe para o Provider, que mostra uma mensagem amigavel.
    if (updatedRows != 1) {
      throw StateError('Perfil local nao encontrado.');
    }

    // Bloco 7 - recarrega o usuario apos salvar.
    // Isso garante que a UI use exatamente o valor persistido no banco.
    final updatedUser = await _userRepository.getUser(userId);
    if (updatedUser == null) {
      throw StateError('Perfil local nao encontrado.');
    }

    // Bloco 8 - devolve o perfil atualizado para o Provider.
    return updatedUser;
  }
}
