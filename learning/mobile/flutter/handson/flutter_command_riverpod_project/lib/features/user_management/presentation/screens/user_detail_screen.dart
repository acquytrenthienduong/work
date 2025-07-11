import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_simple.dart';
import 'user_form_screen.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editUser(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.defaultPadding.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Avatar and Basic Info
            _buildUserHeader(),
            SizedBox(height: 24.h),
            
            // Contact Information
            _buildSectionCard(
              title: 'Contact Information',
              icon: Icons.contact_phone,
              children: [
                _buildInfoRow('Email', user.email, Icons.email),
                _buildInfoRow('Phone', user.phone, Icons.phone),
                _buildInfoRow('Website', user.website, Icons.web),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Address Information
            _buildSectionCard(
              title: 'Address',
              icon: Icons.location_on,
              children: [
                _buildInfoRow('Street', user.address.street, Icons.home),
                _buildInfoRow('Suite', user.address.suite, Icons.apartment),
                _buildInfoRow('City', user.address.city, Icons.location_city),
                _buildInfoRow('Zipcode', user.address.zipcode, Icons.markunread_mailbox),
                _buildInfoRow('Coordinates', '${user.address.geo.lat}, ${user.address.geo.lng}', Icons.my_location),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Company Information
            _buildSectionCard(
              title: 'Company',
              icon: Icons.business,
              children: [
                _buildInfoRow('Name', user.company.name, Icons.business_center),
                _buildInfoRow('Catch Phrase', user.company.catchPhrase, Icons.format_quote),
                _buildInfoRow('BS', user.company.bs, Icons.description),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Status Information
            _buildSectionCard(
              title: 'Status',
              icon: Icons.info,
              children: [
                _buildInfoRow('Status', user.isActive ? 'Active' : 'Inactive', Icons.circle, 
                  valueColor: user.isActive ? Colors.green : Colors.orange),
                if (user.createdAt != null)
                  _buildInfoRow('Created', _formatDate(user.createdAt!), Icons.calendar_today),
                if (user.updatedAt != null)
                  _buildInfoRow('Updated', _formatDate(user.updatedAt!), Icons.update),
              ],
            ),
            
            SizedBox(height: 32.h),
            
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: EdgeInsets.all(24.w),
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
        children: [
          CircleAvatar(
            radius: 48.r,
            backgroundColor: Colors.blue,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            user.displayName,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: Colors.grey[600],
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _editUser(context),
            icon: const Icon(Icons.edit),
            label: const Text('Edit User'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _editUser(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(user: user),
      ),
    ).then((result) {
      if (result == true) {
        // User was updated, pop back to previous screen
        Navigator.pop(context, true);
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 