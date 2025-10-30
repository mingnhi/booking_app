import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';

class AuthUtils {
  static void checkAdminAccess(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAdmin()) {
      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền truy cập trang này')),
      );

      // Chuyển hướng về trang chính
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}