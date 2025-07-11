# 🔗 Dependency Injection (DI) Explained với Code Examples

## 🎯 **DI là gì? - Simple Definition**

**Dependency Injection** = Thay vì class **tự tạo** dependencies, nó **nhận** dependencies từ bên ngoài.

---

## 📊 **Code Examples: DI vs Non-DI**

### ❌ **NON-DI (BAD) - Class tự tạo dependencies**

```dart
// ❌ BAD: UserService tự tạo Dio instance
class UserService {
  late final Dio _dio;

  UserService() {
    // CLASS TỰ TẠO DEPENDENCY - NOT DI!
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: Duration(seconds: 10),
    ));
  }

  Future<List<User>> getUsers() async {
    final response = await _dio.get('/users');
    return (response.data as List).map((json) => User.fromJson(json)).toList();
  }
}

// ❌ BAD: UserRepository tự tạo UserService
class UserRepository {
  late final UserService _userService;

  UserRepository() {
    // CLASS TỰ TẠO DEPENDENCY - NOT DI!
    _userService = UserService();
  }

  Future<List<User>> getUsers() => _userService.getUsers();
}

// ❌ BAD: Command tự tạo Repository
class LoadUsersCommand extends Command<List<User>> {
  late final UserRepository _userRepository;

  LoadUsersCommand() {
    // CLASS TỰ TẠO DEPENDENCY - NOT DI!
    _userRepository = UserRepository();
  }

  @override
  Future<List<User>> performAction() => _userRepository.getUsers();
}

// Usage - TIGHTLY COUPLED!
final command = LoadUsersCommand(); // Creates entire dependency chain internally
```

**Problems với Non-DI:**
- ❌ **Tight coupling** - Classes biết cách tạo dependencies
- ❌ **Hard to test** - Không thể mock dependencies
- ❌ **Configuration nightmare** - Config scattered everywhere  
- ❌ **Duplicate code** - Dio setup repeated multiple places
- ❌ **Hard to change** - Muốn đổi API base URL phải sửa nhiều nơi

---

### ✅ **WITH DI (GOOD) - Dependencies được inject từ bên ngoài**

#### **Method 1: Constructor Injection (Most Common)**

```dart
// ✅ GOOD: UserService nhận Dio từ bên ngoài
class UserService {
  final Dio _dio;

  // DEPENDENCY ĐƯỢC INJECT VÀO CONSTRUCTOR!
  UserService(this._dio);

  Future<List<User>> getUsers() async {
    final response = await _dio.get('/users');
    return (response.data as List).map((json) => User.fromJson(json)).toList();
  }
}

// ✅ GOOD: UserRepository nhận UserService từ bên ngoài  
class UserRepository {
  final UserService _userService;

  // DEPENDENCY ĐƯỢC INJECT VÀO CONSTRUCTOR!
  UserRepository(this._userService);

  Future<List<User>> getUsers() => _userService.getUsers();
}

// ✅ GOOD: Command nhận Repository từ bên ngoài
class LoadUsersCommand extends Command<List<User>> {
  final UserRepository _userRepository;

  // DEPENDENCY ĐƯỢC INJECT VÀO CONSTRUCTOR!
  LoadUsersCommand(this._userRepository);

  @override
  Future<List<User>> performAction() => _userRepository.getUsers();
}

// Usage - DEPENDENCIES CREATED OUTSIDE AND INJECTED!
void main() {
  // Tạo dependencies ở 1 nơi (DI Container)
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  final userService = UserService(dio);           // Inject Dio
  final userRepository = UserRepository(userService); // Inject UserService
  final command = LoadUsersCommand(userRepository);   // Inject Repository
  
  // Use command
  command.execute();
}
```

#### **Method 2: Setter Injection**

```dart
// ✅ GOOD: Dependencies injected via setters
class UserService {
  late Dio _dio;

  // DEPENDENCY INJECTED VIA SETTER!
  set dio(Dio dio) => _dio = dio;

  Future<List<User>> getUsers() async {
    final response = await _dio.get('/users');
    return (response.data as List).map((json) => User.fromJson(json)).toList();
  }
}

// Usage
final userService = UserService();
userService.dio = Dio(); // Inject dependency via setter
```

#### **Method 3: Interface Injection**

```dart
// ✅ GOOD: Dependencies injected via interfaces
abstract class DioInjectable {
  void injectDio(Dio dio);
}

class UserService implements DioInjectable {
  late Dio _dio;

  @override
  void injectDio(Dio dio) {
    _dio = dio; // DEPENDENCY INJECTED VIA INTERFACE!
  }

  Future<List<User>> getUsers() async {
    final response = await _dio.get('/users');
    return (response.data as List).map((json) => User.fromJson(json)).toList();
  }
}
```

---

## 🏗️ **DI Container Patterns**

### **Manual DI Container (Simple)**

```dart
// ✅ SIMPLE DI: Manual dependency management
class DIContainer {
  // Singleton instances
  static final _dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  static final _userService = UserService(_dio);
  static final _userRepository = UserRepository(_userService);
  
  // Factory methods - CREATE DEPENDENCIES HERE!
  static Dio get dio => _dio;
  static UserService get userService => _userService;
  static UserRepository get userRepository => _userRepository;
  
  static LoadUsersCommand createLoadUsersCommand() {
    return LoadUsersCommand(_userRepository); // INJECT DEPENDENCY!
  }
}

// Usage
final command = DIContainer.createLoadUsersCommand();
```

### **Provider DI Container (Flutter)**

```dart
// ✅ PROVIDER DI: Using Provider package
void main() {
  runApp(
    MultiProvider(
      providers: [
        // Dependencies created here and injected down the tree
        Provider<Dio>(
          create: (_) => Dio(BaseOptions(baseUrl: 'https://api.example.com')),
        ),
        ProxyProvider<Dio, UserService>(
          update: (_, dio, __) => UserService(dio), // INJECT DIO!
        ),
        ProxyProvider<UserService, UserRepository>(
          update: (_, userService, __) => UserRepository(userService), // INJECT SERVICE!
        ),
        ProxyProvider<UserRepository, LoadUsersCommand>(
          update: (_, repository, __) => LoadUsersCommand(repository), // INJECT REPO!
        ),
      ],
      child: MyApp(),
    ),
  );
}

// Usage in Widget
class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // DEPENDENCIES AUTOMATICALLY INJECTED BY PROVIDER!
    final command = Provider.of<LoadUsersCommand>(context);
    return Container();
  }
}
```

### **Riverpod DI Container (Modern)**

```dart
// ✅ RIVERPOD DI: Type-safe dependency injection
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.com'));
});

final userServiceProvider = Provider<UserService>((ref) {
  final dio = ref.read(dioProvider); // INJECT DIO!
  return UserService(dio);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final userService = ref.read(userServiceProvider); // INJECT SERVICE!
  return UserRepository(userService);
});

final loadUsersCommandProvider = Provider<LoadUsersCommand>((ref) {
  final repository = ref.read(userRepositoryProvider); // INJECT REPOSITORY!
  return LoadUsersCommand(repository);
});

// Usage in Widget
class UserScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // DEPENDENCY AUTOMATICALLY INJECTED BY RIVERPOD!
    final command = ref.read(loadUsersCommandProvider);
    return Container();
  }
}
```

### **GetIt DI Container (Service Locator)**

```dart
// ✅ GETIT DI: Service locator pattern
void setupDI() {
  final getIt = GetIt.instance;
  
  // Register dependencies
  getIt.registerSingleton<Dio>(
    Dio(BaseOptions(baseUrl: 'https://api.example.com'))
  );
  
  getIt.registerSingleton<UserService>(
    UserService(getIt<Dio>()) // INJECT DIO!
  );
  
  getIt.registerSingleton<UserRepository>(
    UserRepository(getIt<UserService>()) // INJECT SERVICE!
  );
  
  getIt.registerFactory<LoadUsersCommand>(
    () => LoadUsersCommand(getIt<UserRepository>()) // INJECT REPOSITORY!
  );
}

// Usage
void main() {
  setupDI();
  runApp(MyApp());
}

class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // DEPENDENCY RETRIEVED FROM CONTAINER!
    final command = GetIt.instance<LoadUsersCommand>();
    return Container();
  }
}
```

---

## 🧪 **DI Benefits: Testing Examples**

### ❌ **Without DI - Hard to Test**

```dart
// ❌ BAD: Cannot mock dependencies
class UserService {
  UserService() {
    _dio = Dio(); // HARDCODED - Cannot mock!
  }
}

// Testing nightmare
void main() {
  test('UserService should load users', () async {
    final userService = UserService();
    
    // PROBLEM: userService uses real Dio!
    // Cannot mock API calls!
    // Tests will make real HTTP requests!
    final users = await userService.getUsers(); // REAL API CALL!
    
    expect(users, isNotEmpty);
  });
}
```

### ✅ **With DI - Easy to Test**

```dart
// ✅ GOOD: Dependencies can be mocked
class UserService {
  final Dio _dio;
  UserService(this._dio); // INJECTABLE!
}

// Easy testing
void main() {
  test('UserService should load users', () async {
    // CREATE MOCK DEPENDENCY!
    final mockDio = MockDio();
    when(mockDio.get('/users')).thenAnswer((_) async => Response(
      data: [{'id': '1', 'name': 'Test', 'email': 'test@example.com'}],
      statusCode: 200,
      requestOptions: RequestOptions(path: '/users'),
    ));
    
    // INJECT MOCK DEPENDENCY!
    final userService = UserService(mockDio);
    
    // Test with mocked dependency
    final users = await userService.getUsers();
    
    expect(users.length, 1);
    expect(users.first.name, 'Test');
    
    // Verify mock was called
    verify(mockDio.get('/users')).called(1);
  });
}
```

---

## 🎯 **How to Identify DI in Code**

### ✅ **This is DI:**
```dart
// 1. Constructor injection
class Service {
  final Dependency _dependency;
  Service(this._dependency); // ← DEPENDENCY INJECTED!
}

// 2. Factory with parameters
static Service createService(Dependency dependency) {
  return Service(dependency); // ← DEPENDENCY INJECTED!
}

// 3. Provider/Container injection
final serviceProvider = Provider<Service>((ref) {
  final dependency = ref.read(dependencyProvider); // ← DEPENDENCY INJECTED!
  return Service(dependency);
});

// 4. Setter injection
class Service {
  late Dependency _dependency;
  set dependency(Dependency dep) => _dependency = dep; // ← DEPENDENCY INJECTED!
}
```

### ❌ **This is NOT DI:**
```dart
// 1. Internal creation
class Service {
  Service() {
    _dependency = Dependency(); // ← NOT DI! Self-created
  }
}

// 2. Static/Global access
class Service {
  void doSomething() {
    GlobalDependency.instance.call(); // ← NOT DI! Global access
  }
}

// 3. Factory methods without parameters
static Service createService() {
  return Service(Dependency()); // ← NOT DI! Internal creation
}
```

---

## 🚀 **Evolution: From Non-DI to DI**

### Step 1: Non-DI Code
```dart
class UserService {
  UserService() {
    _dio = Dio(); // BAD: Self-created
  }
}
```

### Step 2: Add Constructor Parameter (DI!)
```dart
class UserService {
  final Dio _dio;
  UserService(this._dio); // GOOD: Dependency injected!
}
```

### Step 3: Add DI Container
```dart
// DI Container manages all dependencies
final userServiceProvider = Provider<UserService>((ref) {
  final dio = ref.read(dioProvider);
  return UserService(dio); // Dependencies injected by container
});
```

---

## 💡 **Key Takeaways**

### 🎯 **DI = Dependencies come from OUTSIDE the class**

1. ✅ **Constructor injection:** `Service(dependency)`
2. ✅ **Setter injection:** `service.dependency = dep`
3. ✅ **Interface injection:** `service.inject(dependency)`
4. ✅ **Container injection:** Provider/GetIt/etc manages dependencies

### 🚫 **NOT DI = Class creates its own dependencies**

1. ❌ **Internal creation:** `_dep = Dependency()` inside class
2. ❌ **Global access:** `GlobalService.instance`
3. ❌ **Static methods:** `StaticHelper.doSomething()`

### 🏆 **Best DI Approach in Flutter:**

```dart
// Riverpod: Type-safe, auto-managed, testable
final serviceProvider = Provider<Service>((ref) {
  final dependency = ref.read(dependencyProvider); // Auto-injected!
  return Service(dependency);
});
```

**🎯 Bottom Line: DI = Class nhận dependencies từ bên ngoài, không tự tạo!** 