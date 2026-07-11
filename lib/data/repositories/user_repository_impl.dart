import '../../domain/entities/user.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../datasources/local/database_helper.dart';

class UserRepositoryImpl implements IUserRepository {
  UserRepositoryImpl([DatabaseHelper? dbHelper])
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  @override
  Future<User?> getUser(int id) {
    return _dbHelper.getUser(id);
  }

  @override
  Future<User?> getFirstUser() {
    return _dbHelper.getFirstUser();
  }

  @override
  Future<int> saveUser(User user) {
    return _dbHelper.insertUser(user);
  }

  @override
  Future<int> updateUser(User user) {
    return _dbHelper.updateUser(user);
  }

  @override
  Future<void> clearUserData(int userId) {
    return _dbHelper.clearUserData(userId);
  }
}
