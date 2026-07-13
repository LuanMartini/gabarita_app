import '../entities/user.dart';
import '../repositories/i_user_repository.dart';

class UpdateUserAvatar {
  UpdateUserAvatar(this._userRepository);

  final IUserRepository _userRepository;

  Future<User> call({
    required int userId,
    required String? avatarPath,
  }) async {
    final normalizedPath = avatarPath?.trim();
    final storedPath = normalizedPath == null || normalizedPath.isEmpty
        ? null
        : normalizedPath;

    final updatedRows = await _userRepository.updateUserAvatar(
      userId: userId,
      avatarPath: storedPath,
    );
    if (updatedRows != 1) {
      throw StateError('Perfil local nao encontrado.');
    }

    final updatedUser = await _userRepository.getUser(userId);
    if (updatedUser == null) {
      throw StateError('Perfil local nao encontrado.');
    }

    return updatedUser;
  }
}
