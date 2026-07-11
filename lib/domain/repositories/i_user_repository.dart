import '../entities/user.dart';

abstract class IUserRepository {
  Future<User?> getUser(int id);
  Future<User?> getFirstUser();
  Future<int> saveUser(User user);
  Future<int> updateUser(User user);
  Future<void> clearUserData(int userId);
}
