import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_simple.dart';
import '../commands/user_commands.dart';
import '../providers/user_providers.dart';
import '../widgets/user_list_item.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_widget.dart';
import 'user_detail_screen.dart';
import 'user_form_screen.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  late final LoadUsersCommand _loadUsersCommand;
  late final DeleteUserCommand _deleteUserCommand;
  late final SearchUsersCommand _searchUsersCommand;
  
  final TextEditingController _searchController = TextEditingController();
  List<User> _currentUsers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize commands
    _loadUsersCommand = ref.read(loadUsersCommandProvider);
    _deleteUserCommand = ref.read(deleteUserCommandProvider);
    _searchUsersCommand = ref.read(searchUsersCommandProvider);
    
    // Setup listeners
    _loadUsersCommand.addListener(_handleLoadUsersResult);
    _deleteUserCommand.addListener(_handleDeleteUserResult);
    _searchUsersCommand.addListener(_handleSearchUsersResult);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsersCommand.execute();
    });
  }

  @override
  void dispose() {
    _loadUsersCommand.removeListener(_handleLoadUsersResult);
    _deleteUserCommand.removeListener(_handleDeleteUserResult);
    _searchUsersCommand.removeListener(_handleSearchUsersResult);
    _searchController.dispose();
    super.dispose();
  }

  void _handleLoadUsersResult() {
    if (_loadUsersCommand.isSuccess) {
      setState(() {
        _currentUsers = _loadUsersCommand.data ?? [];
      });
    } else if (_loadUsersCommand.isFailure) {
      _showErrorSnackBar(_loadUsersCommand.failure!.userMessage);
    }
  }

  void _handleDeleteUserResult() {
    if (_deleteUserCommand.isSuccess) {
      _showSuccessSnackBar('User deleted successfully');
      // Refresh the list
      _loadUsersCommand.execute();
    } else if (_deleteUserCommand.isFailure) {
      _showErrorSnackBar(_deleteUserCommand.failure!.userMessage);
    }
  }

  void _handleSearchUsersResult() {
    if (_searchUsersCommand.isSuccess) {
      setState(() {
        _currentUsers = _searchUsersCommand.data ?? [];
      });
    } else if (_searchUsersCommand.isFailure) {
      _showErrorSnackBar(_searchUsersCommand.failure!.userMessage);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      _loadUsersCommand.execute();
    } else {
      setState(() {
        _isSearching = true;
      });
      _searchUsersCommand.executeWith(query);
    }
  }

  void _onUserTap(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
  }

  void _onDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUserCommand.executeWith(user.id);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _onAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserFormScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadUsersCommand.execute();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUsersCommand.execute(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(AppConstants.defaultPadding.w),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius.r),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // User List
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddUser,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserList() {
    // Show loading state
    if (_loadUsersCommand.isExecuting && _currentUsers.isEmpty) {
      return const LoadingWidget(message: 'Loading users...');
    }

    // Show search loading state
    if (_searchUsersCommand.isExecuting && _isSearching) {
      return const LoadingWidget(message: 'Searching users...');
    }

    // Show error state
    if (_loadUsersCommand.isFailure && _currentUsers.isEmpty) {
      return ErrorWidget(
        message: _loadUsersCommand.failure!.userMessage,
        onRetry: () => _loadUsersCommand.execute(),
      );
    }

    // Show empty state
    if (_currentUsers.isEmpty) {
      return EmptyWidget(
        message: _isSearching ? 'No users found' : 'No users available',
        onAction: _isSearching ? null : _onAddUser,
        actionText: _isSearching ? null : 'Add User',
      );
    }

    // Show user list
    return RefreshIndicator(
      onRefresh: () async {
        await _loadUsersCommand.execute();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(AppConstants.defaultPadding.w),
        itemCount: _currentUsers.length,
        itemBuilder: (context, index) {
          final user = _currentUsers[index];
          return UserListItem(
            user: user,
            onTap: () => _onUserTap(user),
            onDelete: () => _onDeleteUser(user),
            isDeleting: _deleteUserCommand.isExecuting,
          );
        },
      ),
    );
  }
} 