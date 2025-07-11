import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/commands/command.dart';
import '../../domain/entities/user_simple.dart';
import '../../domain/repositories/user_repository.dart';
import '../providers/user_providers.dart';

/// Load Users Command
class LoadUsersCommand extends Command<List<User>> {
  LoadUsersCommand({required super.ref}) : super(name: 'LoadUsersCommand');

  @override
  Future<Result<List<User>>> performAction() async {
    final repository = ref.read(userRepositoryProvider);
    return repository.getUsers();
  }
}

/// Load User by ID Command
class LoadUserByIdCommand extends Command1<User, String> {
  LoadUserByIdCommand({required super.ref})
      : super(
          name: 'LoadUserByIdCommand',
          action: (id) async {
            final repository = ref.read(userRepositoryProvider);
            return repository.getUserById(id);
          },
        );
}

/// Create User Command
class CreateUserCommand extends Command1<User, User> {
  CreateUserCommand({required super.ref})
      : super(
          name: 'CreateUserCommand',
          action: (user) async {
            final repository = ref.read(userRepositoryProvider);
            return repository.createUser(user);
          },
        );
}

/// Update User Command
class UpdateUserCommand extends Command1<User, User> {
  UpdateUserCommand({required super.ref})
      : super(
          name: 'UpdateUserCommand',
          action: (user) async {
            final repository = ref.read(userRepositoryProvider);
            return repository.updateUser(user);
          },
        );
}

/// Delete User Command
class DeleteUserCommand extends Command1<void, String> {
  DeleteUserCommand({required super.ref})
      : super(
          name: 'DeleteUserCommand',
          action: (id) async {
            final repository = ref.read(userRepositoryProvider);
            return repository.deleteUser(id);
          },
        );
}

/// Search Users Command
class SearchUsersCommand extends Command1<List<User>, String> {
  SearchUsersCommand({required super.ref})
      : super(
          name: 'SearchUsersCommand',
          action: (query) async {
            final repository = ref.read(userRepositoryProvider);
            return repository.searchUsers(query);
          },
        );
}

/// User form data for create/update operations
class UserFormData {
  final String name;
  final String email;
  final String phone;
  final String website;
  final String street;
  final String suite;
  final String city;
  final String zipcode;
  final String companyName;
  final String companyCatchPhrase;
  final String companyBs;

  const UserFormData({
    required this.name,
    required this.email,
    required this.phone,
    required this.website,
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
    required this.companyName,
    required this.companyCatchPhrase,
    required this.companyBs,
  });

  User toUser({String? id}) {
    return User(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      website: website,
      address: UserAddress(
        street: street,
        suite: suite,
        city: city,
        zipcode: zipcode,
        geo: const UserGeo(lat: '0', lng: '0'), // Default values
      ),
      company: UserCompany(
        name: companyName,
        catchPhrase: companyCatchPhrase,
        bs: companyBs,
      ),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserFormData.fromUser(User user) {
    return UserFormData(
      name: user.name,
      email: user.email,
      phone: user.phone,
      website: user.website,
      street: user.address.street,
      suite: user.address.suite,
      city: user.address.city,
      zipcode: user.address.zipcode,
      companyName: user.company.name,
      companyCatchPhrase: user.company.catchPhrase,
      companyBs: user.company.bs,
    );
  }
}

/// Create User from Form Command
class CreateUserFromFormCommand extends Command1<User, UserFormData> {
  CreateUserFromFormCommand({required super.ref})
      : super(
          name: 'CreateUserFromFormCommand',
          action: (formData) async {
            final repository = ref.read(userRepositoryProvider);
            final user = formData.toUser();
            return repository.createUser(user);
          },
        );
}

/// Update User from Form Command
class UpdateUserFromFormCommand extends Command2<User, String, UserFormData> {
  UpdateUserFromFormCommand({required super.ref})
      : super(
          name: 'UpdateUserFromFormCommand',
          action: (userId, formData) async {
            final repository = ref.read(userRepositoryProvider);
            final user = formData.toUser(id: userId);
            return repository.updateUser(user);
          },
        );
} 