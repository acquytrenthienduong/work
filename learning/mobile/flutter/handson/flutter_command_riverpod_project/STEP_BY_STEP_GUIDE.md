# 🚀 Step-by-Step Guide: Command Pattern + Riverpod

## 📋 Mục tiêu
Sau khi hoàn thành guide này, bạn sẽ có một Flutter app hoàn chỉnh với Command Pattern + Riverpod, có thể:
- Load danh sách users từ API
- Tạo user mới
- Xóa user
- Tự động handle loading states, errors

## 🛠️ Prerequisites
- Flutter SDK đã cài đặt
- VS Code hoặc Android Studio
- Hiểu biết cơ bản về Flutter widgets

---

## PHASE 1: PROJECT SETUP

### Step 1: Tạo Flutter Project
```bash
# Terminal/Command Prompt
flutter create my_command_app
cd my_command_app
```

### Step 2: Thêm Dependencies
Mở `pubspec.yaml` và thêm:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # HTTP Client  
  dio: ^5.4.0
  
  # UI Utilities
  flutter_screenutil: ^5.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

Chạy:
```bash
flutter pub get
```

### Step 3: Tạo Cấu trúc Thư mục
```
lib/
├── main.dart
├── core/
│   ├── commands/
│   │   └── command.dart
│   ├── network/
│   │   └── dio_provider.dart
│   └── constants/
│       └── app_constants.dart
├── models/
│   └── user.dart
├── services/
│   └── user_service.dart
└── screens/
    └── user_list_screen.dart
```

---

## PHASE 2: CORE INFRASTRUCTURE

### Step 4: Tạo Command Base Classes
**Tạo file:** `lib/core/commands/command.dart`
```dart
import 'package:flutter/foundation.dart';

// Base Command class - VIẾT 1 LẦN, DÙNG MÃI MÃI
abstract class Command<T> extends ChangeNotifier {
  bool _isExecuting = false;
  T? _data;
  String? _errorMessage;

  // Getters tự động
  bool get isExecuting => _isExecuting;
  bool get hasData => _data != null;
  bool get hasError => _errorMessage != null;
  T? get data => _data;
  String? get errorMessage => _errorMessage;

  // LOGIC CHUNG CHO TẤT CẢ COMMANDS
  Future<void> execute() async {
    if (_isExecuting) return; // Auto prevent duplicate

    _isExecuting = true;
    _errorMessage = null;
    notifyListeners(); // UI tự động update

    try {
      _data = await performAction(); // Gọi business logic
    } catch (e) {
      _errorMessage = e.toString(); // Auto handle error
    } finally {
      _isExecuting = false;
      notifyListeners(); // UI tự động update
    }
  }

  // CHỈ CẦN IMPLEMENT METHOD NÀY CHO MỖI FEATURE
  Future<T> performAction();

  void clearResult() {
    _data = null;
    _errorMessage = null;
    notifyListeners();
  }
}

// Command với 1 parameter
abstract class Command1<T, P> extends Command<T> {
  P? _parameter;

  Future<void> executeWith(P parameter) async {
    _parameter = parameter;
    await execute();
  }

  @override
  Future<T> performAction() {
    if (_parameter == null) {
      throw Exception('Parameter required for Command1');
    }
    return performActionWith(_parameter!);
  }

  // Implement này thay vì performAction()
  Future<T> performActionWith(P parameter);
}
```

### Step 5: Tạo App Constants
**Tạo file:** `lib/core/constants/app_constants.dart`
```dart
class AppConstants {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String usersEndpoint = '/users';
}
```

### Step 6: Setup Dio Provider
**Tạo file:** `lib/core/network/dio_provider.dart`
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  
  dio.options = BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  return dio;
});
```

---

## PHASE 3: DATA LAYER

### Step 7: Tạo User Model
**Tạo file:** `lib/models/user.dart`
```dart
class User {
  final String id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  // Parse từ JSON (API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  // Convert sang JSON (gửi lên API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
```

### Step 8: Tạo User Service
**Tạo file:** `lib/services/user_service.dart`
```dart
import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';
import '../models/user.dart';

class UserService {
  final Dio _dio;

  UserService(this._dio);

  // Load users từ API
  Future<List<User>> getUsers() async {
    final response = await _dio.get(AppConstants.usersEndpoint);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Create user mới
  Future<User> createUser(String name, String email) async {
    final response = await _dio.post(
      AppConstants.usersEndpoint,
      data: {
        'name': name,
        'email': email,
      },
    );

    if (response.statusCode == 201) {
      return User.fromJson(response.data);
    } else {
      throw Exception('Failed to create user');
    }
  }

  // Delete user
  Future<void> deleteUser(String id) async {
    final response = await _dio.delete('${AppConstants.usersEndpoint}/$id');
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}

// Riverpod Provider cho UserService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_provider.dart';

final userServiceProvider = Provider<UserService>((ref) {
  final dio = ref.read(dioProvider);
  return UserService(dio);
});
```

---

## PHASE 4: COMMAND IMPLEMENTATIONS

### Step 9: Tạo User Commands
**Tạo file:** `lib/commands/user_commands.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/commands/command.dart';
import '../models/user.dart';
import '../services/user_service.dart';

// Load Users Command - CHỈ 4 LINES!
class LoadUsersCommand extends Command<List<User>> {
  final UserService userService;

  LoadUsersCommand(this.userService);

  @override
  Future<List<User>> performAction() async {
    return await userService.getUsers();
  }
}

// Create User Command - CHỈ 4 LINES!
class CreateUserCommand extends Command1<User, Map<String, String>> {
  final UserService userService;

  CreateUserCommand(this.userService);

  @override
  Future<User> performActionWith(Map<String, String> userData) async {
    return await userService.createUser(
      userData['name']!,
      userData['email']!,
    );
  }
}

// Delete User Command - CHỈ 4 LINES!
class DeleteUserCommand extends Command1<void, String> {
  final UserService userService;

  DeleteUserCommand(this.userService);

  @override
  Future<void> performActionWith(String userId) async {
    return await userService.deleteUser(userId);
  }
}

// Providers cho Commands
final loadUsersCommandProvider = Provider<LoadUsersCommand>((ref) {
  final userService = ref.read(userServiceProvider);
  return LoadUsersCommand(userService);
});

final createUserCommandProvider = Provider<CreateUserCommand>((ref) {
  final userService = ref.read(userServiceProvider);
  return CreateUserCommand(userService);
});

final deleteUserCommandProvider = Provider<DeleteUserCommand>((ref) {
  final userService = ref.read(userServiceProvider);
  return DeleteUserCommand(userService);
});
```

---

## PHASE 5: UI IMPLEMENTATION

### Step 10: Tạo User List Screen
**Tạo file:** `lib/screens/user_list_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../commands/user_commands.dart';
import '../models/user.dart';

class UserListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  late final LoadUsersCommand _loadUsersCommand;
  late final CreateUserCommand _createUserCommand;
  late final DeleteUserCommand _deleteUserCommand;

  @override
  void initState() {
    super.initState();
    
    // Lấy commands từ providers
    _loadUsersCommand = ref.read(loadUsersCommandProvider);
    _createUserCommand = ref.read(createUserCommandProvider);
    _deleteUserCommand = ref.read(deleteUserCommandProvider);
    
    // Setup listeners
    _loadUsersCommand.addListener(_handleLoadResult);
    _createUserCommand.addListener(_handleCreateResult);
    _deleteUserCommand.addListener(_handleDeleteResult);
    
    // Load users ngay khi vào screen
    _loadUsersCommand.execute();
  }

  @override
  void dispose() {
    _loadUsersCommand.removeListener(_handleLoadResult);
    _createUserCommand.removeListener(_handleCreateResult);
    _deleteUserCommand.removeListener(_handleDeleteResult);
    super.dispose();
  }

  // Handle kết quả load users
  void _handleLoadResult() {
    if (_loadUsersCommand.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_loadUsersCommand.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle kết quả create user
  void _handleCreateResult() {
    if (_createUserCommand.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User created successfully!')),
      );
      _loadUsersCommand.execute(); // Refresh danh sách
    } else if (_createUserCommand.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_createUserCommand.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle kết quả delete user
  void _handleDeleteResult() {
    if (_deleteUserCommand.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully!')),
      );
      _loadUsersCommand.execute(); // Refresh danh sách
    } else if (_deleteUserCommand.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_deleteUserCommand.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadUsersCommand.execute(),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    // SỬ DỤNG LISTENABLEBUILDER ĐỂ AUTO-REBUILD
    return ListenableBuilder(
      listenable: _loadUsersCommand,
      builder: (context, child) {
        // Loading state
        if (_loadUsersCommand.isExecuting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading users...'),
              ],
            ),
          );
        }

        // Error state
        if (_loadUsersCommand.hasError && !_loadUsersCommand.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error: ${_loadUsersCommand.errorMessage}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadUsersCommand.execute(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (!_loadUsersCommand.hasData || _loadUsersCommand.data!.isEmpty) {
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

        // Success state - hiển thị danh sách users
        return ListView.builder(
          itemCount: _loadUsersCommand.data!.length,
          itemBuilder: (context, index) {
            final user = _loadUsersCommand.data![index];
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
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
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
              // Execute create command
              _createUserCommand.executeWith({
                'name': nameController.text,
                'email': emailController.text,
              });
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
              // Execute delete command
              _deleteUserCommand.executeWith(user.id);
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

### Step 11: Update Main App
**Update file:** `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/user_list_screen.dart';

void main() {
  runApp(
    ProviderScope( // Wrap với ProviderScope cho Riverpod
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Command Pattern Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: UserListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## PHASE 6: TESTING & RUNNING

### Step 12: Test App
```bash
flutter run
```

**Expected behavior:**
1. App loads và fetch users từ API
2. Hiển thị loading spinner
3. Hiển thị danh sách users
4. Có thể tạo user mới
5. Có thể xóa user
6. Error handling tự động

### Step 13: Debug Common Issues

**Issue 1:** `Target of URI doesn't exist`
- **Fix:** Chạy `flutter pub get`

**Issue 2:** Network error
- **Fix:** Test trên real device hoặc enable internet trong emulator

**Issue 3:** Commands không hoạt động
- **Fix:** Kiểm tra providers đã setup đúng chưa

---

## 🎯 PHASE 7: ADDING NEW FEATURES

### Step 14: Thêm Search Feature (Ví dụ mở rộng)

**Thêm vào UserService:**
```dart
Future<List<User>> searchUsers(String query) async {
  final users = await getUsers();
  return users.where((user) => 
    user.name.toLowerCase().contains(query.toLowerCase()) ||
    user.email.toLowerCase().contains(query.toLowerCase())
  ).toList();
}
```

**Tạo Search Command:**
```dart
class SearchUsersCommand extends Command1<List<User>, String> {
  final UserService userService;

  SearchUsersCommand(this.userService);

  @override
  Future<List<User>> performActionWith(String query) async {
    return await userService.searchUsers(query);
  }
}
```

**Thêm Search UI:**
```dart
// Trong UserListScreen, thêm search bar
TextField(
  decoration: InputDecoration(hintText: 'Search users...'),
  onChanged: (query) => _searchUsersCommand.executeWith(query),
)
```

---

## ✅ CHECKLIST HOÀN THÀNH

- [ ] ✅ Project setup với dependencies
- [ ] ✅ Command base classes
- [ ] ✅ User model & service
- [ ] ✅ User commands implementation
- [ ] ✅ UI screen với ListenableBuilder
- [ ] ✅ Error handling tự động
- [ ] ✅ Loading states tự động
- [ ] ✅ App chạy thành công

---

## 🚀 NEXT STEPS

Sau khi hoàn thành guide này, bạn có thể:

1. **Thêm features mới** - Chỉ cần tạo Command mới
2. **Improve UI** - Thêm animations, better design
3. **Add offline support** - Cache data locally
4. **Add testing** - Unit tests cho Commands
5. **Add more complex workflows** - Multi-step operations

## 🎯 KEY TAKEAWAYS

1. **Command Pattern** giúp tách biệt UI và business logic
2. **Setup 1 lần, benefit mãi mãi** 
3. **Consistent behavior** across toàn bộ app
4. **Easy to test** và maintain
5. **Scalable** cho large applications

**🎉 Congratulations! Bạn đã implement thành công Command Pattern + Riverpod!** 