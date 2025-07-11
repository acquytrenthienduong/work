import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_simple.dart';
import '../commands/user_commands.dart';
import '../providers/user_providers.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final User? user; // null for create, not null for edit

  const UserFormScreen({super.key, this.user});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _streetController;
  late final TextEditingController _suiteController;
  late final TextEditingController _cityController;
  late final TextEditingController _zipcodeController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyCatchPhraseController;
  late final TextEditingController _companyBsController;

  // Commands
  late final CreateUserFromFormCommand _createCommand;
  late final UpdateUserFromFormCommand _updateCommand;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();
    _streetController = TextEditingController();
    _suiteController = TextEditingController();
    _cityController = TextEditingController();
    _zipcodeController = TextEditingController();
    _companyNameController = TextEditingController();
    _companyCatchPhraseController = TextEditingController();
    _companyBsController = TextEditingController();

    // Initialize commands
    _createCommand = ref.read(createUserFromFormCommandProvider);
    _updateCommand = ref.read(updateUserFromFormCommandProvider);

    // Setup listeners
    _createCommand.addListener(_handleCreateResult);
    _updateCommand.addListener(_handleUpdateResult);

    // Pre-fill form if editing
    if (_isEditing) {
      _prefillForm();
    }
  }

  @override
  void dispose() {
    _createCommand.removeListener(_handleCreateResult);
    _updateCommand.removeListener(_handleUpdateResult);
    
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _streetController.dispose();
    _suiteController.dispose();
    _cityController.dispose();
    _zipcodeController.dispose();
    _companyNameController.dispose();
    _companyCatchPhraseController.dispose();
    _companyBsController.dispose();
    
    super.dispose();
  }

  void _prefillForm() {
    if (widget.user != null) {
      final user = widget.user!;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _websiteController.text = user.website;
      _streetController.text = user.address.street;
      _suiteController.text = user.address.suite;
      _cityController.text = user.address.city;
      _zipcodeController.text = user.address.zipcode;
      _companyNameController.text = user.company.name;
      _companyCatchPhraseController.text = user.company.catchPhrase;
      _companyBsController.text = user.company.bs;
    }
  }

  void _handleCreateResult() {
    if (_createCommand.isSuccess) {
      _showSuccessSnackBar('User created successfully');
      Navigator.pop(context, true);
    } else if (_createCommand.isFailure) {
      _showErrorSnackBar(_createCommand.failure!.userMessage);
    }
  }

  void _handleUpdateResult() {
    if (_updateCommand.isSuccess) {
      _showSuccessSnackBar('User updated successfully');
      Navigator.pop(context, true);
    } else if (_updateCommand.isFailure) {
      _showErrorSnackBar(_updateCommand.failure!.userMessage);
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = UserFormData(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        street: _streetController.text.trim(),
        suite: _suiteController.text.trim(),
        city: _cityController.text.trim(),
        zipcode: _zipcodeController.text.trim(),
        companyName: _companyNameController.text.trim(),
        companyCatchPhrase: _companyCatchPhraseController.text.trim(),
        companyBs: _companyBsController.text.trim(),
      );

      if (_isEditing) {
        _updateCommand.executeWith(widget.user!.id, formData);
      } else {
        _createCommand.executeWith(formData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _createCommand.isExecuting || _updateCommand.isExecuting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'Create User'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.defaultPadding.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information
              _buildSectionCard(
                title: 'Personal Information',
                icon: Icons.person,
                children: [
                  _buildTextFormField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildTextFormField(
                    controller: _phoneController,
                    label: 'Phone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildTextFormField(
                    controller: _websiteController,
                    label: 'Website',
                    icon: Icons.web,
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a website';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Address Information
              _buildSectionCard(
                title: 'Address',
                icon: Icons.location_on,
                children: [
                  _buildTextFormField(
                    controller: _streetController,
                    label: 'Street',
                    icon: Icons.home,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a street address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildTextFormField(
                    controller: _suiteController,
                    label: 'Suite',
                    icon: Icons.apartment,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a suite';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildTextFormField(
                    controller: _cityController,
                    label: 'City',
                    icon: Icons.location_city,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a city';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildTextFormField(
                    controller: _zipcodeController,
                    label: 'Zipcode',
                    icon: Icons.markunread_mailbox,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a zipcode';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Company Information
              _buildSectionCard(
                title: 'Company',
                icon: Icons.business,
                children: [
                  _buildTextFormField(
                    controller: _companyNameController,
                    label: 'Company Name',
                    icon: Icons.business_center,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a company name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildTextFormField(
                    controller: _companyCatchPhraseController,
                    label: 'Catch Phrase',
                    icon: Icons.format_quote,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a catch phrase';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildTextFormField(
                    controller: _companyBsController,
                    label: 'Business',
                    icon: Icons.description,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter business description';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // Submit Button
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius.r),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update User' : 'Create User',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: Colors.blue,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius.r),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }
} 