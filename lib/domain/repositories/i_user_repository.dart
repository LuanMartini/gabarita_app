import '../entities/user.dart';

// Bloco 1 - contrato do repositorio de usuario.
// A tela e o dominio nao precisam saber se o perfil esta no SQLite,
// SharedPreferences ou outro armazenamento.
abstract class IUserRepository {
  // Bloco 2 - busca um usuario por id.
  Future<User?> getUser(int id);

  // Bloco 3 - busca o primeiro perfil local.
  Future<User?> getFirstUser();

  // Bloco 4 - salva um novo usuario.
  Future<int> saveUser(User user);

  // Bloco 5 - atualiza todos os dados de um usuario.
  Future<int> updateUser(User user);

  // Bloco 6 - atualiza somente o nome.
  Future<int> updateUserName({required int userId, required String name});

  // Bloco 7 - atualiza somente a foto/avatar.
  Future<int> updateUserAvatar({required int userId, String? avatarPath});

  // Bloco 8 - limpa dados locais do usuario.
  Future<void> clearUserData(int userId);
}
