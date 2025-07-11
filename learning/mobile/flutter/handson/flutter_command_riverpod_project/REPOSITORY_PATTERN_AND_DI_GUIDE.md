# 🏛️ Repository Pattern & Dependency Injection Guide

## 📚 Repository Pattern Explained

### 🎯 **Repository Pattern là gì?**

Repository Pattern là một **abstraction layer** nằm giữa business logic và data sources. Nó "giấu" chi tiết về cách lấy data và cung cấp interface clean cho app sử dụng.

### 🤔 **Tại sao cần Repository Pattern?**

#### ❌ **Without Repository (Direct Service Call):**
```dart
// Command gọi trực tiếp service - TIGHT COUPLING
class LoadUsersCommand extends Command<List<User>> {
  final ApiService apiService;
  final DatabaseService dbService;
  final CacheService cacheService;

  @override
  Future<List<User>> performAction() async {
    // Business logic bị mix với data logic - BAD!
    try {
      // Try cache first
      final cachedUsers = await cacheService.getUsers();
      if (cachedUsers.isNotEmpty) return cachedUsers;
      
      // Try API
      final apiUsers = await apiService.getUsers();
      if (apiUsers.isNotEmpty) {
        await cacheService.saveUsers(apiUsers);
        await dbService.saveUsers(apiUsers);
        return apiUsers;
      }
      
      // Fallback to database
      return await dbService.getUsers();
    } catch (e) {
      throw Exception('Failed to load users');
    }
  }
}
```

**Problems:**
- ❌ Command biết quá nhiều về data sources
- ❌ Khó test (phải mock 3 services)
- ❌ Duplicate logic across multiple commands
- ❌ Hard to change data strategy

#### ✅ **With Repository (Clean Separation):**
```dart
// Repository handle tất cả data complexity
class LoadUsersCommand extends Command<List<User>> {
  final UserRepository userRepository;

  @override
  Future<List<User>> performAction() async {
    return await userRepository.getUsers(); // SIMPLE & CLEAN!
  }
}
```

**Benefits:**
- ✅ Command chỉ focus vào business logic
- ✅ Easy testing (mock 1 repository)
- ✅ Reusable data logic
- ✅ Easy to change data strategy

---

## 🏗️ **Repository Pattern Implementation**

### Step 1: Define Repository Interface (Contract)
```dart
// lib/domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> getUserById(String id);
  Future<User> createUser(User user);
  Future<User> updateUser(User user);
  Future<void> deleteUser(String id);
  
  // Advanced operations
  Future<List<User>> searchUsers(String query);
  Future<void> syncUsers(); // Online/offline sync
  Stream<List<User>> watchUsers(); // Real-time updates
}
```

### Step 2: Implement Repository (Data Logic)
```dart
// lib/data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserApiDataSource _apiDataSource;
  final UserLocalDataSource _localDataSource;
  final UserCacheDataSource _cacheDataSource;
  final ConnectivityService _connectivity;

  UserRepositoryImpl({
    required UserApiDataSource apiDataSource,
    required UserLocalDataSource localDataSource, 
    required UserCacheDataSource cacheDataSource,
    required ConnectivityService connectivity,
  }) : _apiDataSource = apiDataSource,
       _localDataSource = localDataSource,
       _cacheDataSource = cacheDataSource,
       _connectivity = connectivity;

  @override
  Future<List<User>> getUsers() async {
    // REPOSITORY HANDLES ALL DATA COMPLEXITY
    
    // 1. Try cache first (fastest)
    final cachedUsers = await _cacheDataSource.getUsers();
    if (cachedUsers.isNotEmpty && _isCacheValid()) {
      return cachedUsers;
    }

    // 2. Check connectivity
    if (await _connectivity.isConnected()) {
      try {
        // 3. Fetch from API
        final apiUsers = await _apiDataSource.getUsers();
        
        // 4. Update cache and local storage
        await _cacheDataSource.saveUsers(apiUsers);
        await _localDataSource.saveUsers(apiUsers);
        
        return apiUsers;
      } catch (e) {
        // 5. API failed - fallback to local storage
        return await _localDataSource.getUsers();
      }
    } else {
      // 6. Offline - use local storage
      return await _localDataSource.getUsers();
    }
  }

  @override
  Future<User> createUser(User user) async {
    if (await _connectivity.isConnected()) {
      try {
        // Create online
        final createdUser = await _apiDataSource.createUser(user);
        
        // Update local storage
        await _localDataSource.saveUser(createdUser);
        await _cacheDataSource.invalidateUsers(); // Clear cache
        
        return createdUser;
      } catch (e) {
        // Queue for later sync
        return await _localDataSource.createPendingUser(user);
      }
    } else {
      // Offline - create locally and queue for sync
      return await _localDataSource.createPendingUser(user);
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    if (await _connectivity.isConnected()) {
      try {
        await _apiDataSource.deleteUser(id);
        await _localDataSource.deleteUser(id);
        await _cacheDataSource.invalidateUsers();
      } catch (e) {
        // Mark for deletion when online
        await _localDataSource.markForDeletion(id);
      }
    } else {
      await _localDataSource.markForDeletion(id);
    }
  }

  @override
  Stream<List<User>> watchUsers() {
    // Return real-time stream from local storage
    return _localDataSource.watchUsers();
  }

  @override
  Future<void> syncUsers() async {
    if (!await _connectivity.isConnected()) return;

    // Sync pending operations
    final pendingUsers = await _localDataSource.getPendingUsers();
    for (final user in pendingUsers) {
      try {
        await _apiDataSource.createUser(user);
        await _localDataSource.removePendingUser(user.id);
      } catch (e) {
        // Keep pending for next sync
      }
    }

    // Sync deletions
    final markedForDeletion = await _localDataSource.getUsersMarkedForDeletion();
    for (final id in markedForDeletion) {
      try {
        await _apiDataSource.deleteUser(id);
        await _localDataSource.removeDeleteionMark(id);
      } catch (e) {
        // Keep marked for next sync
      }
    }
  }

  bool _isCacheValid() {
    // Check if cache is still valid (e.g., < 5 minutes old)
    final lastCacheTime = _cacheDataSource.getLastCacheTime();
    return DateTime.now().difference(lastCacheTime).inMinutes < 5;
  }
}
```

### Step 3: Data Sources (Implementation Details)
```dart
// lib/data/datasources/user_api_datasource.dart
class UserApiDataSource {
  final Dio _dio;

  Future<List<User>> getUsers() async {
    final response = await _dio.get('/users');
    return (response.data as List)
        .map((json) => User.fromJson(json))
        .toList();
  }

  Future<User> createUser(User user) async {
    final response = await _dio.post('/users', data: user.toJson());
    return User.fromJson(response.data);
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/users/$id');
  }
}

// lib/data/datasources/user_local_datasource.dart  
class UserLocalDataSource {
  final Database _database;

  Future<List<User>> getUsers() async {
    final maps = await _database.query('users');
    return maps.map((json) => User.fromJson(json)).toList();
  }

  Future<void> saveUsers(List<User> users) async {
    final batch = _database.batch();
    for (final user in users) {
      batch.insert('users', user.toJson(), 
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<User> createPendingUser(User user) async {
    final pendingUser = user.copyWith(isPending: true);
    await _database.insert('pending_users', pendingUser.toJson());
    return pendingUser;
  }

  Stream<List<User>> watchUsers() {
    // Return stream that updates when database changes
    return Stream.periodic(Duration(seconds: 1), (_) => getUsers()).asyncMap((_) => getUsers());
  }
}

// lib/data/datasources/user_cache_datasource.dart
class UserCacheDataSource {
  final Map<String, dynamic> _cache = {};
  DateTime? _lastCacheTime;

  Future<List<User>> getUsers() async {
    final cached = _cache['users'] as List<User>?;
    return cached ?? [];
  }

  Future<void> saveUsers(List<User> users) async {
    _cache['users'] = users;
    _lastCacheTime = DateTime.now();
  }

  Future<void> invalidateUsers() async {
    _cache.remove('users');
    _lastCacheTime = null;
  }

  DateTime getLastCacheTime() => _lastCacheTime ?? DateTime(1970);
}
```

### Step 4: Use Repository in Commands
```dart
// lib/commands/user_commands.dart
class LoadUsersCommand extends Command<List<User>> {
  final UserRepository _userRepository;

  LoadUsersCommand(this._userRepository);

  @override
  Future<List<User>> performAction() async {
    // SIMPLE! Repository handles all complexity
    return await _userRepository.getUsers();
  }
}

class CreateUserCommand extends Command1<User, Map<String, String>> {
  final UserRepository _userRepository;

  CreateUserCommand(this._userRepository);

  @override
  Future<User> performActionWith(Map<String, String> userData) async {
    final user = User(
      id: '', // Will be set by API
      name: userData['name']!,
      email: userData['email']!,
    );
    
    return await _userRepository.createUser(user);
  }
}

class SyncUsersCommand extends Command<void> {
  final UserRepository _userRepository;

  SyncUsersCommand(this._userRepository);

  @override
  Future<void> performAction() async {
    await _userRepository.syncUsers();
  }
}
```

---

## 🔗 **Dependency Injection: Tại sao Riverpod?**

### 🤔 **DI Options Comparison:**

| Approach | Setup | Type Safety | Performance | Learning Curve | Recommended |
|----------|-------|-------------|-------------|----------------|-------------|
| **Manual DI** | ⭐ Easy | ❌ No | ⭐⭐⭐⭐⭐ Fast | ⭐ Easy | 👶 Learning |
| **get_it** | ⭐⭐⭐ Medium | ❌ No | ⭐⭐⭐⭐ Fast | ⭐⭐ Medium | 🏢 Large apps |
| **Provider** | ⭐⭐ Easy | ⭐⭐⭐ Partial | ⭐⭐⭐ Good | ⭐⭐ Medium | 📱 Most apps |
| **Riverpod** | ⭐⭐ Easy | ⭐⭐⭐⭐⭐ Full | ⭐⭐⭐⭐ Good | ⭐⭐⭐ Medium | 🚀 Modern apps |

### ✅ **Why Riverpod for DI?**

#### 1. **Type Safety:**
```dart
// ❌ get_it - Runtime errors
final userRepo = GetIt.instance<UserRepository>(); // Could be null!

// ❌ Manual DI - No compile-time checking  
final userRepo = ServiceLocator.get<UserRepository>(); // Runtime error

// ✅ Riverpod - Compile-time safety
final userRepo = ref.read(userRepositoryProvider); // Guaranteed to exist!
```

#### 2. **Dependency Graph Management:**
```dart
// Riverpod automatically manages dependency tree
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.com'));
});

final connectivityProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final apiDataSourceProvider = Provider<UserApiDataSource>((ref) {
  final dio = ref.read(dioProvider); // Auto dependency injection
  return UserApiDataSource(dio);
});

final localDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSource(); // Could inject database here
});

final cacheDataSourceProvider = Provider<UserCacheDataSource>((ref) {
  return UserCacheDataSource();
});

// Repository with all dependencies auto-injected
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    apiDataSource: ref.read(apiDataSourceProvider),
    localDataSource: ref.read(localDataSourceProvider),
    cacheDataSource: ref.read(cacheDataSourceProvider),
    connectivity: ref.read(connectivityProvider),
  );
});

// Commands with repository auto-injected
final loadUsersCommandProvider = Provider<LoadUsersCommand>((ref) {
  final userRepository = ref.read(userRepositoryProvider);
  return LoadUsersCommand(userRepository);
});
```

#### 3. **Easy Testing:**
```dart
// Override dependencies for testing
void main() {
  testWidgets('LoadUsersCommand should load users', (tester) async {
    // Mock repository
    final mockUserRepository = MockUserRepository();
    when(() => mockUserRepository.getUsers())
        .thenAnswer((_) async => [User(id: '1', name: 'Test', email: 'test@example.com')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override real repository with mock
          userRepositoryProvider.overrideWithValue(mockUserRepository),
        ],
        child: MyApp(),
      ),
    );

    // Test widget that uses the command
    final command = container.read(loadUsersCommandProvider);
    await command.execute();
    
    expect(command.hasData, true);
    expect(command.data!.length, 1);
  });
}
```

#### 4. **Hot Reload Friendly:**
```dart
// Riverpod providers work seamlessly with hot reload
// Dependencies are automatically recreated when needed
```

#### 5. **Scoped Dependencies:**
```dart
// Different scopes for different parts of app
final familyUserRepositoryProvider = Provider.family<UserRepository, String>((ref, familyId) {
  return UserRepositoryImpl(familyId: familyId);
});

// Auto dispose when not needed
final autoDisposeUserRepositoryProvider = Provider.autoDispose<UserRepository>((ref) {
  final repo = UserRepositoryImpl();
  
  // Cleanup when provider is disposed
  ref.onDispose(() {
    repo.dispose();
  });
  
  return repo;
});
```

---

## 🏗️ **Complete Architecture Example**

### Project Structure:
```dart
lib/
├── main.dart
├── app/
│   ├── providers.dart           # All Riverpod providers
│   └── router.dart
├── domain/
│   ├── entities/               # Pure business objects
│   │   └── user.dart
│   └── repositories/           # Repository interfaces  
│       └── user_repository.dart
├── data/
│   ├── models/                 # Data transfer objects
│   │   └── user_model.dart
│   ├── repositories/           # Repository implementations
│   │   └── user_repository_impl.dart
│   └── datasources/           # Data sources
│       ├── user_api_datasource.dart
│       ├── user_local_datasource.dart
│       └── user_cache_datasource.dart
├── presentation/
│   ├── commands/              # Business logic commands
│   │   └── user_commands.dart
│   ├── screens/               # UI screens
│   │   └── user_list_screen.dart
│   └── widgets/               # Reusable widgets
└── core/
    ├── commands/              # Base command classes
    │   └── command.dart
    ├── network/               # Network setup
    │   └── dio_client.dart
    └── errors/                # Error handling
        └── app_errors.dart
```

### Providers Setup:
```dart
// lib/app/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core providers
final dioProvider = Provider<Dio>((ref) => DioClient.create());
final connectivityProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

// Data source providers
final userApiDataSourceProvider = Provider<UserApiDataSource>((ref) {
  return UserApiDataSource(ref.read(dioProvider));
});

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSource();
});

final userCacheDataSourceProvider = Provider<UserCacheDataSource>((ref) {
  return UserCacheDataSource();
});

// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    apiDataSource: ref.read(userApiDataSourceProvider),
    localDataSource: ref.read(userLocalDataSourceProvider),
    cacheDataSource: ref.read(userCacheDataSourceProvider),
    connectivity: ref.read(connectivityProvider),
  );
});

// Command providers
final loadUsersCommandProvider = Provider<LoadUsersCommand>((ref) {
  return LoadUsersCommand(ref.read(userRepositoryProvider));
});

final createUserCommandProvider = Provider<CreateUserCommand>((ref) {
  return CreateUserCommand(ref.read(userRepositoryProvider));
});

final syncUsersCommandProvider = Provider<SyncUsersCommand>((ref) {
  return SyncUsersCommand(ref.read(userRepositoryProvider));
});
```

### Widget Usage:
```dart
// lib/presentation/screens/user_list_screen.dart
class UserListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  late LoadUsersCommand _loadUsersCommand;
  late CreateUserCommand _createUserCommand;

  @override
  void initState() {
    super.initState();
    
    // Get commands from Riverpod providers
    _loadUsersCommand = ref.read(loadUsersCommandProvider);
    _createUserCommand = ref.read(createUserCommandProvider);
    
    // Setup listeners
    _loadUsersCommand.addListener(_handleLoadResult);
    _createUserCommand.addListener(_handleCreateResult);
    
    // Load initial data
    _loadUsersCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: ListenableBuilder(
        listenable: _loadUsersCommand,
        builder: (context, child) {
          // UI logic using repository data
          if (_loadUsersCommand.isExecuting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (_loadUsersCommand.hasError) {
            return Center(child: Text('Error: ${_loadUsersCommand.errorMessage}'));
          }
          
          if (_loadUsersCommand.hasData) {
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

  void _handleLoadResult() {
    if (_loadUsersCommand.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users')),
      );
    }
  }

  void _handleCreateResult() {
    if (_createUserCommand.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User created successfully!')),
      );
      _loadUsersCommand.execute(); // Refresh list
    }
  }

  void _showCreateUserDialog() {
    // Dialog to create new user
    // Uses _createUserCommand.executeWith()
  }
}
```

---

## 🎯 **Summary & Benefits**

### 🏛️ **Repository Pattern Benefits:**
1. ✅ **Separation of Concerns** - Business logic ≠ Data logic
2. ✅ **Easy Testing** - Mock repository instead of multiple services
3. ✅ **Consistent Data Strategy** - Cache, offline, sync logic in one place
4. ✅ **Flexibility** - Easy to change data sources without affecting business logic
5. ✅ **Reusability** - Same repository used by multiple commands

### 🔗 **Riverpod DI Benefits:**  
1. ✅ **Type Safety** - Compile-time dependency checking
2. ✅ **Auto Dependency Management** - No manual dependency graph
3. ✅ **Easy Testing** - Provider overrides for mocking
4. ✅ **Hot Reload Friendly** - Dependencies recreate seamlessly
5. ✅ **Scoped Dependencies** - Auto disposal and family providers

### 🚀 **Combined Power:**
```dart
Repository Pattern + Riverpod DI = 
  Clean Architecture + Type Safety + Easy Testing + Maintainability
```

**🎯 Bottom Line: Repository abstracts data complexity, Riverpod manages dependencies safely!** 