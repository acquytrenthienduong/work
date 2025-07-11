# 🔄 Design Patterns Comparison: Command vs Command + Result

## 📋 Command Pattern (Current Implementation)

### ✅ Ưu điểm:
- Simple to implement and understand
- Auto error handling với try-catch
- UI states tự động (loading/error/success)
- Consistent behavior across app

### ❌ Hạn chế:
- Error handling bị "ẩn" trong try-catch
- Khó differentiate giữa các loại errors
- Error messages có thể không user-friendly
- Debugging khó hơn khi có nhiều error types

```dart
// Current: Command chỉ return exception message
if (_loadUsersCommand.hasError) {
  showSnackBar('Error: ${_loadUsersCommand.errorMessage}'); // Generic!
}
```

---

## 🚀 Command + Result Objects Pattern

### ✅ Ưu điểm Enhanced:
- **Explicit error handling** - biết rõ error type
- **Type-safe errors** - compile-time checking
- **Better error messages** - custom cho từng error
- **Easy testing** - mock specific error scenarios
- **Clean separation** - business logic vs presentation

### 🎯 Implementation:

### Step 1: Define Result Types
```dart
// lib/core/result/result.dart
abstract class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

// Custom error types
abstract class AppError {
  final String message;
  final String userMessage;
  const AppError(this.message, this.userMessage);
}

class NetworkError extends AppError {
  const NetworkError() : super(
    'Network connection failed',
    'Please check your internet connection'
  );
}

class ServerError extends AppError {
  final int statusCode;
  const ServerError(this.statusCode) : super(
    'Server error: $statusCode',
    'Something went wrong. Please try again.'
  );
}

class ValidationError extends AppError {
  const ValidationError(String field) : super(
    'Validation failed for $field',
    'Please check your input and try again'
  );
}
```

### Step 2: Enhanced Command Base Class
```dart
// lib/core/commands/result_command.dart
abstract class ResultCommand<T> extends ChangeNotifier {
  bool _isExecuting = false;
  Result<T>? _result;

  // Getters
  bool get isExecuting => _isExecuting;
  bool get hasResult => _result != null;
  bool get isSuccess => _result is Success<T>;
  bool get isFailure => _result is Failure<T>;
  
  T? get data => _result is Success<T> ? (_result as Success<T>).data : null;
  AppError? get error => _result is Failure<T> ? (_result as Failure<T>).error : null;
  
  // User-friendly error message
  String? get userErrorMessage => error?.userMessage;

  Future<void> execute() async {
    if (_isExecuting) return;

    _isExecuting = true;
    _result = null;
    notifyListeners();

    try {
      _result = await performAction(); // Returns Result<T>
    } catch (e) {
      // Fallback for unexpected errors
      _result = Failure(AppError('Unexpected error: $e', 'Something went wrong'));
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  // Implementation returns Result instead of throwing
  Future<Result<T>> performAction();
}
```

### Step 3: Enhanced Service Layer
```dart
// lib/services/user_service_enhanced.dart
class UserServiceEnhanced {
  final Dio _dio;

  UserServiceEnhanced(this._dio);

  Future<Result<List<User>>> getUsers() async {
    try {
      final response = await _dio.get('/users');
      
      if (response.statusCode == 200) {
        final users = (response.data as List)
            .map((json) => User.fromJson(json))
            .toList();
        return Success(users);
      } else {
        return Failure(ServerError(response.statusCode!));
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        return Failure(NetworkError());
      } else if (e.response?.statusCode != null) {
        return Failure(ServerError(e.response!.statusCode!));
      } else {
        return Failure(AppError('Network error', 'Please try again'));
      }
    } catch (e) {
      return Failure(AppError('Unexpected error: $e', 'Something went wrong'));
    }
  }

  Future<Result<User>> createUser(String name, String email) async {
    // Validation first
    if (name.isEmpty) {
      return Failure(ValidationError('name'));
    }
    if (!email.contains('@')) {
      return Failure(ValidationError('email'));
    }

    try {
      final response = await _dio.post('/users', data: {
        'name': name,
        'email': email,
      });

      if (response.statusCode == 201) {
        return Success(User.fromJson(response.data));
      } else {
        return Failure(ServerError(response.statusCode!));
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        return Failure(NetworkError());
      } else {
        return Failure(ServerError(e.response?.statusCode ?? 500));
      }
    }
  }
}
```

### Step 4: Enhanced Commands
```dart
// lib/commands/user_commands_enhanced.dart
class LoadUsersCommandEnhanced extends ResultCommand<List<User>> {
  final UserServiceEnhanced userService;

  LoadUsersCommandEnhanced(this.userService);

  @override
  Future<Result<List<User>>> performAction() async {
    return await userService.getUsers();
  }
}

class CreateUserCommandEnhanced extends ResultCommand<User> {
  final UserServiceEnhanced userService;
  
  CreateUserCommandEnhanced(this.userService);

  Future<void> executeWith(String name, String email) async {
    // Store parameters for performAction
    _name = name;
    _email = email;
    await execute();
  }

  String? _name;
  String? _email;

  @override
  Future<Result<User>> performAction() async {
    return await userService.createUser(_name!, _email!);
  }
}
```

### Step 5: Enhanced UI with Better Error Handling
```dart
// lib/screens/user_list_screen_enhanced.dart
class UserListScreenEnhanced extends ConsumerStatefulWidget {
  @override
  ConsumerState<UserListScreenEnhanced> createState() => _UserListScreenEnhancedState();
}

class _UserListScreenEnhancedState extends ConsumerState<UserListScreenEnhanced> {
  late LoadUsersCommandEnhanced _loadUsersCommand;
  late CreateUserCommandEnhanced _createUserCommand;

  @override
  void initState() {
    super.initState();
    _loadUsersCommand = ref.read(loadUsersCommandEnhancedProvider);
    _createUserCommand = ref.read(createUserCommandEnhancedProvider);
    
    _loadUsersCommand.addListener(_handleLoadResult);
    _createUserCommand.addListener(_handleCreateResult);
    
    _loadUsersCommand.execute();
  }

  void _handleLoadResult() {
    if (_loadUsersCommand.isFailure) {
      final error = _loadUsersCommand.error!;
      
      // Different UI for different error types
      if (error is NetworkError) {
        _showRetrySnackBar(error.userMessage);
      } else if (error is ServerError) {
        _showErrorDialog(error.userMessage);
      } else {
        _showErrorSnackBar(error.userMessage);
      }
    }
  }

  void _handleCreateResult() {
    if (_createUserCommand.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsersCommand.execute(); // Refresh
    } else if (_createUserCommand.isFailure) {
      final error = _createUserCommand.error!;
      
      if (error is ValidationError) {
        _showValidationError(error.userMessage);
      } else {
        _showErrorSnackBar(error.userMessage);
      }
    }
  }

  void _showRetrySnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _loadUsersCommand.execute(),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Server Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadUsersCommand.execute();
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Validation Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users Enhanced')),
      body: ListenableBuilder(
        listenable: _loadUsersCommand,
        builder: (context, child) {
          if (_loadUsersCommand.isExecuting) {
            return Center(child: CircularProgressIndicator());
          }

          if (_loadUsersCommand.isFailure && _loadUsersCommand.data == null) {
            final error = _loadUsersCommand.error!;
            return _buildErrorState(error);
          }

          if (_loadUsersCommand.isSuccess) {
            return _buildUserList(_loadUsersCommand.data!);
          }

          return Center(child: Text('No data'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState(AppError error) {
    IconData icon;
    Color color;
    String actionText;
    VoidCallback action;

    if (error is NetworkError) {
      icon = Icons.wifi_off;
      color = Colors.orange;
      actionText = 'Check Connection';
      action = () => _loadUsersCommand.execute();
    } else if (error is ServerError) {
      icon = Icons.error;
      color = Colors.red;
      actionText = 'Retry';
      action = () => _loadUsersCommand.execute();
    } else {
      icon = Icons.warning;
      color = Colors.grey;
      actionText = 'Retry';
      action = () => _loadUsersCommand.execute();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color),
          SizedBox(height: 16),
          Text(
            error.userMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: action,
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<User> users) {
    if (users.isEmpty) {
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
              child: Text('Create User'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(user.name[0].toUpperCase()),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(user),
            ),
          ),
        );
      },
    );
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createUserCommand.executeWith(
                nameController.text,
                emailController.text,
              );
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete command
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📊 Comparison Table:

| Feature | Command Only | Command + Result |
|---------|-------------|------------------|
| **Setup Complexity** | ⭐⭐ Simple | ⭐⭐⭐⭐ More setup |
| **Error Granularity** | ⭐⭐ Generic | ⭐⭐⭐⭐⭐ Specific |
| **Type Safety** | ⭐⭐ Runtime | ⭐⭐⭐⭐⭐ Compile-time |
| **User Experience** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Testing** | ⭐⭐⭐ OK | ⭐⭐⭐⭐⭐ Easy |
| **Maintenance** | ⭐⭐⭐ OK | ⭐⭐⭐⭐⭐ Excellent |
| **Performance** | ⭐⭐⭐⭐⭐ Fast | ⭐⭐⭐⭐ Slightly slower |

---

## 🎯 Recommendations:

### 🥇 **Start Simple (Command Only):**
- Small apps (< 10 features)
- Prototype/MVP phase
- Team mới với patterns

### 🚀 **Upgrade to Command + Result:**
- Production apps
- Complex error scenarios  
- Better user experience required
- Team có kinh nghiệm

### 🔄 **Migration Strategy:**
1. **Phase 1:** Implement Command Pattern (current)
2. **Phase 2:** Add Result types gradually
3. **Phase 3:** Migrate commands one by one
4. **Phase 4:** Enhanced UI error handling

**💡 Kết luận: Command + Result = Best of both worlds!** 