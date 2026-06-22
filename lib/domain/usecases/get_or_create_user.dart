import '../entities/user.dart';
import '../repositories/i_user_repository.dart';

class GetOrCreateUser {
  GetOrCreateUser(this._userRepository);

  final IUserRepository _userRepository;

  Future<User> call({
    String defaultName = 'Lucas Mendes',
  }) async {
    final existingUser = await _userRepository.getFirstUser();
    if (existingUser != null) return existingUser;

    final user = User(name: defaultName, studyGoalMinutes: 45);
    final id = await _userRepository.saveUser(user);
    return user.copyWith(id: id);
  }
}
