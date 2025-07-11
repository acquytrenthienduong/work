# Command Design Pattern trong Flutter

## Khái niệm cơ bản

Command Pattern là một behavioral design pattern giúp đóng gói các hành động (requests) thành các đối tượng độc lập. Trong Flutter, pattern này đặc biệt hữu ích để:

1. **Quản lý trạng thái**: Theo dõi `running`, `error`, `completed`
2. **Ngăn duplicate execution**: Tránh việc thực thi cùng lúc
3. **Tự động xử lý lỗi**: Capture exceptions
4. **Tách biệt UI và logic**: UI chỉ trigger command

## Cấu trúc cơ bản

```dart
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  bool get running => _running;
  
  Result<T>? _result;
  bool get error => _result is Error;
  bool get completed => _result is Ok;
  
  Future<void> execute();
}
```

## Ví dụ thực tế: User Management

### 1. Các thành phần chính

#### Models
- `User`: Đại diện cho người dùng
- `Result<T>`: Wrapper cho kết quả success/error

#### Services
- `UserService`: Xử lý business logic (CRUD operations)
- Simulate API calls với delay và random errors

#### Commands
- `Command0<T>`: Command không tham số (load users)
- `Command1<T, A>`: Command với 1 tham số (create, update, delete)

#### ViewModel
- `UserViewModel`: Quản lý state và commands
- Tự động update UI khi có thay đổi

### 2. Lợi ích của Command Pattern

#### Tách biệt UI và Business Logic
```dart
// UI chỉ cần trigger command
ElevatedButton(
  onPressed: () => viewModel.loadUsers.execute(),
  child: Text('Load Users'),
)

// Business logic được đóng gói trong command
class LoadUsersCommand extends Command<List<User>> {
  Future<void> execute() async {
    // Handle loading, error, success states
  }
}
```

#### Tự động quản lý trạng thái
```dart
// UI tự động reflect command state
if (command.running) {
  return CircularProgressIndicator();
}

if (command.error) {
  return ErrorWidget();
}

if (command.completed) {
  return SuccessWidget();
}
```

#### Ngăn duplicate execution
```dart
Future<void> execute() async {
  if (_running) return; // Ngăn chặn multiple executions
  
  _running = true;
  try {
    await _performAction();
  } finally {
    _running = false;
  }
}
```

### 3. Cách sử dụng trong ví dụ

#### Khởi tạo Commands
```dart
class UserViewModel extends ChangeNotifier {
  late final Command0<List<User>> loadUsers;
  late final Command1<User, Map<String, String>> createUser;
  
  UserViewModel() {
    loadUsers = Command0(_loadUsers);
    createUser = Command1(_createUser);
  }
}
```

#### Sử dụng trong UI
```dart
// Loading state
ListenableBuilder(
  listenable: viewModel.loadUsers,
  builder: (context, child) {
    if (viewModel.loadUsers.running) {
      return CircularProgressIndicator();
    }
    return UserList();
  },
)

// Execute command
FloatingActionButton(
  onPressed: () => viewModel.createUser.execute({
    'name': 'John Doe',
    'email': 'john@example.com',
  }),
  child: Icon(Icons.add),
)
```

### 4. Xử lý kết quả

#### Theo dõi kết quả command
```dart
@override
void initState() {
  super.initState();
  viewModel.createUser.addListener(_handleCreateResult);
}

void _handleCreateResult() {
  if (viewModel.createUser.completed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User created successfully')),
    );
    viewModel.createUser.clearResult();
  } else if (viewModel.createUser.error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating user')),
    );
    viewModel.createUser.clearResult();
  }
}
```

## So sánh với các pattern khác

### Vs. Direct Service Calls
❌ **Trực tiếp gọi service**
```dart
// UI phải tự quản lý loading state
bool isLoading = false;
String? errorMessage;

void loadUsers() async {
  setState(() { isLoading = true; });
  try {
    final users = await userService.getUsers();
    setState(() { 
      isLoading = false;
      this.users = users;
    });
  } catch (e) {
    setState(() { 
      isLoading = false;
      errorMessage = e.toString();
    });
  }
}
```

✅ **Với Command Pattern**
```dart
// UI chỉ cần trigger command
loadUsersCommand.execute();

// Command tự động quản lý states
if (loadUsersCommand.running) CircularProgressIndicator();
if (loadUsersCommand.error) ErrorWidget();
if (loadUsersCommand.completed) SuccessWidget();
```

### Vs. Provider/Riverpod
- **Provider/Riverpod**: Tốt cho state management
- **Command Pattern**: Tốt cho action management và complex workflows

## Khi nào sử dụng Command Pattern?

### Phù hợp khi:
- Cần quản lý complex async operations
- Muốn tránh duplicate executions
- Cần track command lifecycle (running, error, completed)
- Có nhiều UI components cần reflect cùng command state

### Không phù hợp khi:
- Simple state management
- Không cần track command states
- Ứng dụng đơn giản với ít async operations

## Best Practices

1. **Đặt tên command rõ ràng**: `loadUsers`, `createUser`, `updateProfile`
2. **Sử dụng typed parameters**: `Command1<User, CreateUserData>`
3. **Clear results sau khi xử lý**: `command.clearResult()`
4. **Combine với other patterns**: Repository, Service Layer
5. **Testing**: Mock commands dễ dàng hơn direct service calls

## Kết luận

Command Pattern trong Flutter giúp:
- Tách biệt UI và business logic
- Tự động quản lý async states
- Ngăn chặn race conditions
- Tăng tính testability
- Làm code dễ maintain và scale

Đây là một pattern mạnh mẽ cho các ứng dụng Flutter có nhiều async operations phức tạp. 