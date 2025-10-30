import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPromptScreen extends StatelessWidget {
  const LoginPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: const Color(0xFF2474E5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Yêu cầu đăng nhập',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2525),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vui lòng đăng nhập để truy cập tính năng này.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF607D8B),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2474E5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Đăng nhập',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth/register');
                  },
                  child: Text(
                    'Chưa có tài khoản? Đăng ký',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2474E5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: Text(
                    'Quay lại trang chủ',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF607D8B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}