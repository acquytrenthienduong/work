import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';
import '../commands/user_commands.dart';

// Data Source Provider
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  final dio = ref.read(dioProvider);
  return UserRemoteDataSourceImpl(dio);
});

// Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final remoteDataSource = ref.read(userRemoteDataSourceProvider);
  return UserRepositoryImpl(remoteDataSource);
});

// Command Providers
final loadUsersCommandProvider = Provider<LoadUsersCommand>((ref) {
  return LoadUsersCommand(ref: ref);
});

final loadUserByIdCommandProvider = Provider<LoadUserByIdCommand>((ref) {
  return LoadUserByIdCommand(ref: ref);
});

final createUserCommandProvider = Provider<CreateUserCommand>((ref) {
  return CreateUserCommand(ref: ref);
});

final updateUserCommandProvider = Provider<UpdateUserCommand>((ref) {
  return UpdateUserCommand(ref: ref);
});

final deleteUserCommandProvider = Provider<DeleteUserCommand>((ref) {
  return DeleteUserCommand(ref: ref);
});

final searchUsersCommandProvider = Provider<SearchUsersCommand>((ref) {
  return SearchUsersCommand(ref: ref);
});

final createUserFromFormCommandProvider = Provider<CreateUserFromFormCommand>((ref) {
  return CreateUserFromFormCommand(ref: ref);
});

final updateUserFromFormCommandProvider = Provider<UpdateUserFromFormCommand>((ref) {
  return UpdateUserFromFormCommand(ref: ref);
});

// Command Factory - tạo commands theo yêu cầu
final commandFactoryProvider = Provider<CommandFactory>((ref) {
  return CommandFactory(ref);
});

class CommandFactory {
  final Ref ref;
  
  CommandFactory(this.ref);
  
  LoadUsersCommand createLoadUsersCommand() => LoadUsersCommand(ref: ref);
  LoadUserByIdCommand createLoadUserByIdCommand() => LoadUserByIdCommand(ref: ref);
  CreateUserCommand createCreateUserCommand() => CreateUserCommand(ref: ref);
  UpdateUserCommand createUpdateUserCommand() => UpdateUserCommand(ref: ref);
  DeleteUserCommand createDeleteUserCommand() => DeleteUserCommand(ref: ref);
  SearchUsersCommand createSearchUsersCommand() => SearchUsersCommand(ref: ref);
  CreateUserFromFormCommand createCreateUserFromFormCommand() => CreateUserFromFormCommand(ref: ref);
  UpdateUserFromFormCommand createUpdateUserFromFormCommand() => UpdateUserFromFormCommand(ref: ref);
} 