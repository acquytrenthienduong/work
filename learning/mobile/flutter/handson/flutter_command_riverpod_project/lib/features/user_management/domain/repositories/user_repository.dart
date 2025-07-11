import '../../../../core/commands/command.dart';
import '../entities/user_simple.dart';

/// User repository interface
abstract class UserRepository {
  Future<Result<List<User>>> getUsers();
  Future<Result<User>> getUserById(String id);
  Future<Result<User>> createUser(User user);
  Future<Result<User>> updateUser(User user);
  Future<Result<void>> deleteUser(String id);
  Future<Result<List<User>>> searchUsers(String query);
} 