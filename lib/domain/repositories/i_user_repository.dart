import '../entities/user.dart';

abstract class IUserRepository {
  Future<User?> getUser(int id);
  Future<User?> getFirstUser();
  Future<int> saveUser(User user);
  Future<int> updateUser(User user);
  Future<int> updateUserName({required int userId, required String name});
  Future<int> updateUserAvatar({required int userId, String? avatarPath});
  Future<void> clearUserData(int userId);
}
