import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<List<UserModel>> getUsers();
  Future<UserModel> getUserById(String id);
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String id);
  Future<List<UserModel>> searchUsers(String query);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio _dio;

  UserRemoteDataSourceImpl(this._dio);

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      AppLogger.logger.d('Fetching users from API');
      
      final response = await _dio.get(AppConstants.usersEndpoint);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final users = data.map((json) => UserModel.fromJson(json)).toList();
        
        AppLogger.logger.i('Successfully fetched ${users.length} users');
        return users;
      } else {
        throw ServerFailure('Failed to fetch users: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.logger.e('DioException in getUsers', error: e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in getUsers', error: e);
      throw UnexpectedFailure('Unexpected error occurred: $e');
    }
  }

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      AppLogger.logger.d('Fetching user with id: $id');
      
      final response = await _dio.get('${AppConstants.usersEndpoint}/$id');
      
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);
        AppLogger.logger.i('Successfully fetched user: ${user.name}');
        return user;
      } else {
        throw ServerFailure('Failed to fetch user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.logger.e('DioException in getUserById', error: e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in getUserById', error: e);
      throw UnexpectedFailure('Unexpected error occurred: $e');
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      AppLogger.logger.d('Creating user: ${user.name}');
      
      final response = await _dio.post(
        AppConstants.usersEndpoint,
        data: user.toJson(),
      );
      
      if (response.statusCode == 201) {
        final createdUser = UserModel.fromJson(response.data);
        AppLogger.logger.i('Successfully created user: ${createdUser.name}');
        return createdUser;
      } else {
        throw ServerFailure('Failed to create user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.logger.e('DioException in createUser', error: e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in createUser', error: e);
      throw UnexpectedFailure('Unexpected error occurred: $e');
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      AppLogger.logger.d('Updating user: ${user.name}');
      
      final response = await _dio.put(
        '${AppConstants.usersEndpoint}/${user.id}',
        data: user.toJson(),
      );
      
      if (response.statusCode == 200) {
        final updatedUser = UserModel.fromJson(response.data);
        AppLogger.logger.i('Successfully updated user: ${updatedUser.name}');
        return updatedUser;
      } else {
        throw ServerFailure('Failed to update user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.logger.e('DioException in updateUser', error: e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in updateUser', error: e);
      throw UnexpectedFailure('Unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      AppLogger.logger.d('Deleting user with id: $id');
      
      final response = await _dio.delete('${AppConstants.usersEndpoint}/$id');
      
      if (response.statusCode == 200) {
        AppLogger.logger.i('Successfully deleted user: $id');
      } else {
        throw ServerFailure('Failed to delete user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.logger.e('DioException in deleteUser', error: e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in deleteUser', error: e);
      throw UnexpectedFailure('Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      AppLogger.logger.d('Searching users with query: $query');
      
      // For demo purposes, get all users and filter locally
      final users = await getUsers();
      final filteredUsers = users.where((user) =>
          user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase())
      ).toList();
      
      AppLogger.logger.i('Found ${filteredUsers.length} users matching query: $query');
      return filteredUsers;
    } catch (e) {
      AppLogger.logger.e('Error in searchUsers', error: e);
      rethrow;
    }
  }

  AppFailure _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Connection timeout. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return NetworkFailure('Connection error. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return NotFoundFailure('Resource not found');
        } else if (statusCode == 401) {
          return UnauthorizedFailure('Unauthorized access');
        } else if (statusCode != null && statusCode >= 500) {
          return ServerFailure('Server error ($statusCode)');
        }
        return ServerFailure('Request failed with status code: $statusCode');
      default:
        return UnexpectedFailure('Unexpected network error: ${e.message}');
    }
  }
} 