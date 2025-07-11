// Command Pattern Example - User Management App
import 'package:flutter/material.dart';
import 'dart:async';

// ============================================================================
// MODELS
// ============================================================================

class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}

// ============================================================================
// RESULT CLASS - Để xử lý thành công/thất bại
// ============================================================================

abstract class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Error<T> extends Result<T> {
  final Exception exception;
  const Error(this.exception);
}

// ============================================================================
// COMMAND CLASSES
// ============================================================================

typedef CommandAction0<T> = Future<Result<T>> Function();
typedef CommandAction1<T, A> = Future<Result<T>> Function(A);

// Base Command class
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  bool get error => _result is Error;
  bool get completed => _result is Ok;
  Result<T>? get result => _result;

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(CommandAction0<T> action) async {
    if (_running) return;

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

// Command không có tham số
class Command0<T> extends Command<T> {
  Command0(this._action);
  final CommandAction0<T> _action;

  Future<void> execute() async {
    await _execute(() => _action());
  }
}

// Command có 1 tham số
class Command1<T, A> extends Command<T> {
  Command1(this._action);
  final CommandAction1<T, A> _action;

  Future<void> execute(A argument) async {
    await _execute(() => _action(argument));
  }
}

// ============================================================================
// SERVICES
// ============================================================================

class UserService {
  static final _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final List<User> _users = [];

  // Simulate API delay
  Future<void> _delay() async {
    await Future.delayed(Duration(milliseconds: 800));
  }

  Future<Result<List<User>>> getUsers() async {
    try {
      await _delay();
      
      // Simulate random error (20% chance)
      if (DateTime.now().millisecondsSinceEpoch % 5 == 0) {
        throw Exception('Failed to fetch users from server');
      }

      return Ok(List.from(_users));
    } catch (e) {
      return Error(e as Exception);
    }
  }

  Future<Result<User>> createUser(String name, String email) async {
    try {
      await _delay();
      
      // Validate email
      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }

      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      _users.add(user);
      return Ok(user);
    } catch (e) {
      return Error(e as Exception);
    }
  }

  Future<Result<User>> updateUser(String id, String name, String email) async {
    try {
      await _delay();

      final index = _users.indexWhere((user) => user.id == id);
      if (index == -1) {
        throw Exception('User not found');
      }

      final updatedUser = _users[index].copyWith(name: name, email: email);
      _users[index] = updatedUser;
      return Ok(updatedUser);
    } catch (e) {
      return Error(e as Exception);
    }
  }

  Future<Result<bool>> deleteUser(String id) async {
    try {
      await _delay();

      final removed = _users.removeWhere((user) => user.id == id);
      if (removed == 0) {
        throw Exception('User not found');
      }

      return Ok(true);
    } catch (e) {
      return Error(e as Exception);
    }
  }
}

// ============================================================================
// VIEW MODEL
// ============================================================================

class UserViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  // Commands
  late final Command0<List<User>> loadUsers;
  late final Command1<User, Map<String, String>> createUser;
  late final Command1<User, Map<String, String>> updateUser;
  late final Command1<bool, String> deleteUser;

  List<User> _users = [];
  List<User> get users => _users;

  UserViewModel() {
    // Initialize commands
    loadUsers = Command0(_loadUsers);
    createUser = Command1<User, Map<String, String>>(_createUser);
    updateUser = Command1<User, Map<String, String>>(_updateUser);
    deleteUser = Command1<bool, String>(_deleteUser);

    // Auto-load users when ViewModel is created
    loadUsers.execute();
  }

  // Command actions
  Future<Result<List<User>>> _loadUsers() async {
    final result = await _userService.getUsers();
    if (result is Ok<List<User>>) {
      _users = result.value;
      notifyListeners();
    }
    return result;
  }

  Future<Result<User>> _createUser(Map<String, String> data) async {
    final result = await _userService.createUser(data['name']!, data['email']!);
    if (result is Ok<User>) {
      _users.add(result.value);
      notifyListeners();
    }
    return result;
  }

  Future<Result<User>> _updateUser(Map<String, String> data) async {
    final result = await _userService.updateUser(
      data['id']!,
      data['name']!,
      data['email']!,
    );
    if (result is Ok<User>) {
      final index = _users.indexWhere((user) => user.id == data['id']);
      if (index != -1) {
        _users[index] = result.value;
        notifyListeners();
      }
    }
    return result;
  }

  Future<Result<bool>> _deleteUser(String id) async {
    final result = await _userService.deleteUser(id);
    if (result is Ok<bool>) {
      _users.removeWhere((user) => user.id == id);
      notifyListeners();
    }
    return result;
  }
}

// ============================================================================
// UI WIDGETS
// ============================================================================

class CommandPatternApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Command Pattern Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserViewModel _viewModel = UserViewModel();

  @override
  void initState() {
    super.initState();
    // Listen to command results for showing snackbars
    _viewModel.loadUsers.addListener(_handleLoadResult);
    _viewModel.createUser.addListener(_handleCreateResult);
    _viewModel.updateUser.addListener(_handleUpdateResult);
    _viewModel.deleteUser.addListener(_handleDeleteResult);
  }

  @override
  void dispose() {
    _viewModel.loadUsers.removeListener(_handleLoadResult);
    _viewModel.createUser.removeListener(_handleCreateResult);
    _viewModel.updateUser.removeListener(_handleUpdateResult);
    _viewModel.deleteUser.removeListener(_handleDeleteResult);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleLoadResult() {
    if (_viewModel.loadUsers.error) {
      _showSnackbar('Error loading users', isError: true);
      _viewModel.loadUsers.clearResult();
    }
  }

  void _handleCreateResult() {
    if (_viewModel.createUser.completed) {
      _showSnackbar('User created successfully');
      _viewModel.createUser.clearResult();
    } else if (_viewModel.createUser.error) {
      _showSnackbar('Error creating user', isError: true);
      _viewModel.createUser.clearResult();
    }
  }

  void _handleUpdateResult() {
    if (_viewModel.updateUser.completed) {
      _showSnackbar('User updated successfully');
      _viewModel.updateUser.clearResult();
    } else if (_viewModel.updateUser.error) {
      _showSnackbar('Error updating user', isError: true);
      _viewModel.updateUser.clearResult();
    }
  }

  void _handleDeleteResult() {
    if (_viewModel.deleteUser.completed) {
      _showSnackbar('User deleted successfully');
      _viewModel.deleteUser.clearResult();
    } else if (_viewModel.deleteUser.error) {
      _showSnackbar('Error deleting user', isError: true);
      _viewModel.deleteUser.clearResult();
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        title: 'Create User',
        onSubmit: (name, email) {
          _viewModel.createUser.execute({
            'name': name,
            'email': email,
          });
        },
      ),
    );
  }

  void _showEditUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        title: 'Edit User',
        initialName: user.name,
        initialEmail: user.email,
        onSubmit: (name, email) {
          _viewModel.updateUser.execute({
            'id': user.id,
            'name': name,
            'email': email,
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Command Pattern Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _viewModel.loadUsers.execute(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel.loadUsers,
        builder: (context, child) {
          // Show loading state
          if (_viewModel.loadUsers.running) {
            return Center(child: CircularProgressIndicator());
          }

          // Show error state
          if (_viewModel.loadUsers.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load users'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _viewModel.loadUsers.execute(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show user list
          return child!;
        },
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            if (_viewModel.users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No users found'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showCreateUserDialog,
                      child: Text('Create First User'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: _viewModel.users.length,
              itemBuilder: (context, index) {
                final user = _viewModel.users[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name[0].toUpperCase()),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showEditUserDialog(user),
                        ),
                        ListenableBuilder(
                          listenable: _viewModel.deleteUser,
                          builder: (context, child) {
                            return IconButton(
                              icon: _viewModel.deleteUser.running
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(Icons.delete, color: Colors.red),
                              onPressed: _viewModel.deleteUser.running
                                  ? null
                                  : () => _viewModel.deleteUser.execute(user.id),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// USER FORM DIALOG
// ============================================================================

class UserFormDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final String? initialEmail;
  final Function(String name, String email) onSubmit;

  const UserFormDialog({
    Key? key,
    required this.title,
    this.initialName,
    this.initialEmail,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _UserFormDialogState createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit(_nameController.text, _emailController.text);
              Navigator.of(context).pop();
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================================
// MAIN
// ============================================================================

void main() {
  runApp(CommandPatternApp());
} 