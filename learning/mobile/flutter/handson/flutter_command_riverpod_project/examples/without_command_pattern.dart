// ❌ VÍ DỤ: KHÔNG sử dụng Command Pattern
// Đây là cách truyền thống - tất cả logic trong UI

import 'package:flutter/material.dart';

class UserListScreenWithoutCommand extends StatefulWidget {
  @override
  _UserListScreenWithoutCommandState createState() => _UserListScreenWithoutCommandState();
}

class _UserListScreenWithoutCommandState extends State<UserListScreenWithoutCommand> {
  // 1. PHẢI TỰ QUẢN LÝ TẤT CẢ STATES
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isSearching = false;
  bool _isCreating = false;
  bool _isDeleting = false;
  String? _errorMessage;
  List<User> _users = [];
  List<User> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadUsers(); // Gọi trực tiếp
  }

  // 2. PHẢI VIẾT LOGIC PHỨC TẠP CHO MỖI ACTION
  Future<void> _loadUsers() async {
    // Kiểm tra duplicate manually
    if (_isLoading) return;

    // Set loading state manually
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));
      
      // Simulate random error (để test error handling)
      if (DateTime.now().millisecondsSinceEpoch % 5 == 0) {
        throw Exception('Network error: Failed to load users');
      }

      // Mock data
      final users = [
        User(id: '1', name: 'John Doe', email: 'john@example.com'),
        User(id: '2', name: 'Jane Smith', email: 'jane@example.com'),
        User(id: '3', name: 'Bob Johnson', email: 'bob@example.com'),
      ];

      setState(() {
        _users = users;
        _isLoading = false;
      });

    } catch (e) {
      // Manual error handling
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // 3. PHẢI DUPLICATE LOGIC CHO REFRESH
  Future<void> _refreshUsers() async {
    if (_isRefreshing) return; // Duplicate check

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(Duration(seconds: 1));
      
      if (DateTime.now().millisecondsSinceEpoch % 5 == 0) {
        throw Exception('Refresh failed');
      }

      final users = [
        User(id: '1', name: 'John Doe (Updated)', email: 'john@example.com'),
        User(id: '2', name: 'Jane Smith (Updated)', email: 'jane@example.com'),
      ];

      setState(() {
        _users = users;
        _isRefreshing = false;
      });

    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh error: $e')),
      );
    }
  }

  // 4. PHẢI DUPLICATE LOGIC CHO SEARCH
  Future<void> _searchUsers(String query) async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(Duration(milliseconds: 500));
      
      final filtered = _users.where((user) =>
        user.name.toLowerCase().contains(query.toLowerCase()) ||
        user.email.toLowerCase().contains(query.toLowerCase())
      ).toList();

      setState(() {
        _searchResults = filtered;
        _isSearching = false;
      });

    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = e.toString();
      });
    }
  }

  // 5. PHẢI DUPLICATE LOGIC CHO CREATE
  Future<void> _createUser(String name, String email) async {
    if (_isCreating) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(Duration(seconds: 1));

      if (name.isEmpty || email.isEmpty) {
        throw Exception('Name and email are required');
      }

      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
      );

      setState(() {
        _users.add(newUser);
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User created successfully')),
      );

    } catch (e) {
      setState(() {
        _isCreating = false;
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create error: $e')),
      );
    }
  }

  // 6. PHẢI DUPLICATE LOGIC CHO DELETE
  Future<void> _deleteUser(String userId) async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(Duration(milliseconds: 800));

      setState(() {
        _users.removeWhere((user) => user.id == userId);
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );

    } catch (e) {
      setState(() {
        _isDeleting = false;
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users (Without Command)'),
        actions: [
          // Refresh button
          IconButton(
            icon: _isRefreshing 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: _isSearching 
                  ? Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
          ),
          
          // Body content
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isCreating ? null : () => _showCreateDialog(),
        child: _isCreating 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.add),
      ),
    );
  }

  // 7. PHẢI TỰ HANDLE TẤT CẢ STATES TRONG UI
  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
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
    if (_errorMessage != null && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No users found'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCreateDialog(),
              child: Text('Create First User'),
            ),
          ],
        ),
      );
    }

    // User list
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(user.name[0].toUpperCase()),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: _isDeleting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(user.id),
                ),
          ),
        );
      },
    );
  }

  void _showCreateDialog() {
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
              _createUser(nameController.text, emailController.text);
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }
}

// Simple User model
class User {
  final String id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });
}

/* 
🔍 NHỮNG VẤN ĐỀ CỦA CODE TRÊN:

1. ❌ STATE MANAGEMENT HELL
   - Phải tự track: _isLoading, _isRefreshing, _isSearching, _isCreating, _isDeleting
   - Phải manually setState() everywhere
   - Dễ quên update states

2. ❌ CODE DUPLICATION
   - Logic loading/error/success duplicate 5 lần
   - Try-catch duplicate 5 lần  
   - setState() duplicate everywhere

3. ❌ MIXED RESPONSIBILITIES
   - UI widget phải handle business logic
   - Network calls mixed với UI logic
   - Hard to test business logic separately

4. ❌ ERROR PRONE
   - Dễ quên check duplicate prevention
   - Dễ quên handle errors
   - Dễ quên update UI states

5. ❌ HARD TO MAINTAIN
   - Thay đổi error handling phải update 5 nơi
   - Thêm new action phải duplicate tất cả logic
   - Code rất dài và phức tạp (300+ lines)

6. ❌ TESTING NIGHTMARE
   - Không thể test business logic riêng biệt
   - Phải test toàn bộ UI để test logic
   - Hard to mock states

📊 CODE METRICS:
- Lines of Code: ~300 lines
- Cyclomatic Complexity: Very High
- Code Duplication: ~70%
- Testability: Very Low
- Maintainability: Very Low
*/ 