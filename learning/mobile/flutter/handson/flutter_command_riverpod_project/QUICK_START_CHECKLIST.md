# ⚡ Quick Start Checklist - Command Pattern + Riverpod

## 🎯 Mục tiêu: 30 phút tạo app hoàn chỉnh

### ✅ Phase 1: Setup (5 phút)
```bash
# 1. Tạo project
flutter create my_app && cd my_app

# 2. Thêm dependencies vào pubspec.yaml
flutter_riverpod: ^2.4.9
dio: ^5.4.0

# 3. Install
flutter pub get
```

### ✅ Phase 2: Core Infrastructure (10 phút)

**Tạo:** `lib/core/commands/command.dart`
```dart
abstract class Command<T> extends ChangeNotifier {
  bool _isExecuting = false;
  T? _data;
  String? _errorMessage;

  bool get isExecuting => _isExecuting;
  bool get hasData => _data != null;
  bool get hasError => _errorMessage != null;
  T? get data => _data;
  String? get errorMessage => _errorMessage;

  Future<void> execute() async {
    if (_isExecuting) return;
    _isExecuting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _data = await performAction();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  Future<T> performAction();
}
```

**Tạo:** `lib/models/user.dart`
```dart
class User {
  final String id, name, email;
  User({required this.id, required this.name, required this.email});
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    email: json['email'] ?? '',
  );
}
```

### ✅ Phase 3: Service & Commands (10 phút)

**Tạo:** `lib/services/user_service.dart`
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserService {
  final Dio _dio = Dio();
  
  Future<List<User>> getUsers() async {
    final response = await _dio.get('https://jsonplaceholder.typicode.com/users');
    return (response.data as List).map((json) => User.fromJson(json)).toList();
  }
}

final userServiceProvider = Provider((ref) => UserService());
```

**Tạo:** `lib/commands/user_commands.dart`
```dart
class LoadUsersCommand extends Command<List<User>> {
  final UserService userService;
  LoadUsersCommand(this.userService);
  
  @override
  Future<List<User>> performAction() => userService.getUsers();
}

final loadUsersCommandProvider = Provider<LoadUsersCommand>((ref) {
  return LoadUsersCommand(ref.read(userServiceProvider));
});
```

### ✅ Phase 4: UI Screen (5 phút)

**Update:** `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: UserListScreen());
  }
}

class UserListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  late LoadUsersCommand _loadUsersCommand;

  @override
  void initState() {
    super.initState();
    _loadUsersCommand = ref.read(loadUsersCommandProvider);
    _loadUsersCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: ListenableBuilder(
        listenable: _loadUsersCommand,
        builder: (context, child) {
          if (_loadUsersCommand.isExecuting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (_loadUsersCommand.hasError) {
            return Center(child: Text('Error: ${_loadUsersCommand.errorMessage}'));
          }
          
          if (!_loadUsersCommand.hasData) {
            return Center(child: Text('No data'));
          }

          return ListView.builder(
            itemCount: _loadUsersCommand.data!.length,
            itemBuilder: (context, index) {
              final user = _loadUsersCommand.data![index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.email),
              );
            },
          );
        },
      ),
    );
  }
}
```

### ✅ Test & Run
```bash
flutter run
```

---

## 🚀 Kết quả sau 30 phút:

✅ **App hoàn chỉnh với:**
- Loading states tự động
- Error handling tự động  
- User list từ API
- Clean architecture
- Scalable structure

✅ **Benefits ngay lập tức:**
- Không cần setState() manual
- Không cần try-catch duplicate
- UI tự động update
- Easy to add features

---

## 📈 Next Steps (mở rộng):

### 🔥 Thêm Create User (5 phút)
```dart
// Thêm vào UserService
Future<User> createUser(String name, String email) async {
  final response = await _dio.post('/users', data: {'name': name, 'email': email});
  return User.fromJson(response.data);
}

// Tạo Command mới
class CreateUserCommand extends Command1<User, Map<String, String>> {
  final UserService userService;
  CreateUserCommand(this.userService);
  
  @override
  Future<User> performActionWith(Map<String, String> userData) {
    return userService.createUser(userData['name']!, userData['email']!);
  }
}

// Thêm FloatingActionButton vào UI
floatingActionButton: FloatingActionButton(
  onPressed: () => _createUserCommand.executeWith({'name': 'Test', 'email': 'test@example.com'}),
  child: Icon(Icons.add),
),
```

### 🔥 Thêm Delete User (5 phút)
```dart
// Pattern giống như Create, chỉ khác business logic
class DeleteUserCommand extends Command1<void, String> {
  @override
  Future<void> performActionWith(String userId) => userService.deleteUser(userId);
}
```

---

## 💡 Key Points:

1. **Setup 1 lần** - Command base class
2. **Implement nhanh** - Mỗi feature chỉ 4-6 lines
3. **Auto everything** - Loading, error, success states
4. **Scale dễ dàng** - Thêm command mới = thêm feature mới

**🎯 Command Pattern = Developer productivity booster!** 