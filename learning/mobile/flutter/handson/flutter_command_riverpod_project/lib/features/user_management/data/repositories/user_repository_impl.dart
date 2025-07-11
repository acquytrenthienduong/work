import '../../../../core/commands/command.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_simple.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<User>>> getUsers() async {
    try {
      final userModels = await _remoteDataSource.getUsers();
      final users = userModels.map(_mapModelToEntity).toList();
      return Success(users);
    } on AppFailure catch (e) {
      AppLogger.logger.e('Repository error in getUsers', error: e);
      return Failure(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in getUsers', error: e);
      return Failure(AppFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<User>> getUserById(String id) async {
    try {
      final userModel = await _remoteDataSource.getUserById(id);
      final user = _mapModelToEntity(userModel);
      return Success(user);
    } on AppFailure catch (e) {
      AppLogger.logger.e('Repository error in getUserById', error: e);
      return Failure(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in getUserById', error: e);
      return Failure(AppFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<User>> createUser(User user) async {
    try {
      final userModel = _mapEntityToModel(user);
      final createdUserModel = await _remoteDataSource.createUser(userModel);
      final createdUser = _mapModelToEntity(createdUserModel);
      return Success(createdUser);
    } on AppFailure catch (e) {
      AppLogger.logger.e('Repository error in createUser', error: e);
      return Failure(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in createUser', error: e);
      return Failure(AppFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<User>> updateUser(User user) async {
    try {
      final userModel = _mapEntityToModel(user);
      final updatedUserModel = await _remoteDataSource.updateUser(userModel);
      final updatedUser = _mapModelToEntity(updatedUserModel);
      return Success(updatedUser);
    } on AppFailure catch (e) {
      AppLogger.logger.e('Repository error in updateUser', error: e);
      return Failure(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in updateUser', error: e);
      return Failure(AppFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteUser(String id) async {
    try {
      await _remoteDataSource.deleteUser(id);
      return Success(null);
    } on AppFailure catch (e) {
      AppLogger.logger.e('Repository error in deleteUser', error: e);
      return Failure(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in deleteUser', error: e);
      return Failure(AppFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Result<List<User>>> searchUsers(String query) async {
    try {
      final userModels = await _remoteDataSource.searchUsers(query);
      final users = userModels.map(_mapModelToEntity).toList();
      return Success(users);
    } on AppFailure catch (e) {
      AppLogger.logger.e('Repository error in searchUsers', error: e);
      return Failure(e);
    } catch (e) {
      AppLogger.logger.e('Unexpected error in searchUsers', error: e);
      return Failure(AppFailure.unexpected(e.toString()));
    }
  }

  // Model to Entity mapping
  User _mapModelToEntity(UserModel model) {
    return User(
      id: model.id,
      name: model.name,
      email: model.email,
      phone: model.phone,
      website: model.website,
      address: UserAddress(
        street: model.address.street,
        suite: model.address.suite,
        city: model.address.city,
        zipcode: model.address.zipcode,
        geo: UserGeo(
          lat: model.address.geo.lat,
          lng: model.address.geo.lng,
        ),
      ),
      company: UserCompany(
        name: model.company.name,
        catchPhrase: model.company.catchPhrase,
        bs: model.company.bs,
      ),
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  // Entity to Model mapping
  UserModel _mapEntityToModel(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      website: entity.website,
      address: UserAddressModel(
        street: entity.address.street,
        suite: entity.address.suite,
        city: entity.address.city,
        zipcode: entity.address.zipcode,
        geo: UserGeoModel(
          lat: entity.address.geo.lat,
          lng: entity.address.geo.lng,
        ),
      ),
      company: UserCompanyModel(
        name: entity.company.name,
        catchPhrase: entity.company.catchPhrase,
        bs: entity.company.bs,
      ),
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
} 