import '../repositories/i_user_repository.dart';

class UpdateUserName {
  UpdateUserName(this._userRepository);

  final IUserRepository _userRepository;

  Future<String> call({required int userId, required String name}) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError('Informe seu nome.');
    }
    if (normalizedName.length < 3 || normalizedName.length > 30) {
      throw ArgumentError('O nome deve ter entre 3 e 30 caracteres.');
    }

    final updatedRows = await _userRepository.updateUserName(
      userId: userId,
      name: normalizedName,
    );
    if (updatedRows != 1) {
      throw StateError('Perfil local nao encontrado.');
    }

    return normalizedName;
  }
}
