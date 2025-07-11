import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_simple.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDeleting;

  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
    required this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
      child: ListTile(
        contentPadding: EdgeInsets.all(AppConstants.defaultPadding.w),
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              user.fullAddress,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Delete button
            if (isDeleting)
              SizedBox(
                width: 24.w,
                height: 24.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20.sp,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: 24.w,
                  minHeight: 24.h,
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
} 