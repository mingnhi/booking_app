import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Image.asset(
                        'assets/images/images-removebg.png',
                        height: 120,
                        width: 500,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Text(
                      'Đăng Nhập',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chào mừng bạn đến với ứng dụng đặt vé xe',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 32),
                    Card(
                      elevation: 10, // Slightly reduced for balance
                      shadowColor: Colors.blueAccent.withOpacity(0.3), // Matches gradient
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.blueAccent.shade100.withOpacity(0.5), width: 1), // Gradient-inspired border
                      ),
                      color: Colors.white.withOpacity(0.95), // Semi-transparent to blend with gradient
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Consumer<AuthService>(
                          builder: (context, authService, _) {
                            return Column(
                              children: [
                                if (authService.errorMessage != null)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      authService.errorMessage!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.blueAccent.shade700, // Matches blue accent
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: 'Nhập email của bạn',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.blueGrey.shade200, // Softer hint color
                                    ),
                                    prefixIcon: Icon(Icons.email, color: Colors.blueAccent.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade100, width: 1.5), // Matches gradient
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade400, width: 2), // Brighter focus
                                    ),
                                    filled: true,
                                    fillColor: Colors.blue.shade50.withOpacity(0.5), // Light blue fill to match gradient
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.poppins(
                                    color: Colors.blueGrey.shade800, // Darker for contrast
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 20),
                                TextField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Mật Khẩu',
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.blueAccent.shade700, // Matches blue accent
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: 'Nhập mật khẩu của bạn',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.blueGrey.shade200, // Softer hint color
                                    ),
                                    prefixIcon: Icon(Icons.lock, color: Colors.blueAccent.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade100, width: 1.5), // Matches gradient
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade400, width: 2), // Brighter focus
                                    ),
                                    filled: true,
                                    fillColor: Colors.blue.shade50.withOpacity(0.5), // Light blue fill to match gradient
                                  ),
                                  obscureText: true,
                                  style: GoogleFonts.poppins(
                                    color: Colors.blueGrey.shade800, // Darker for contrast
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 24),
                                authService.isLoading
                                    ? CircularProgressIndicator()
                                    : ElevatedButton(
                                  onPressed: () async {
                                    final email = _emailController.text;
                                    final password = _passwordController.text;
                                    final authService = Provider.of<AuthService>(context, listen: false); // Lấy AuthService
                                    final success = await authService.login(email, password);
                                    if (success != null) {
                                      // Kiểm tra vai trò của người dùng
                                      if (authService.isAdmin()) {
                                        Navigator.pushReplacementNamed(context, '/admin'); // Chuyển hướng đến trang admin
                                      } else {
                                        Navigator.pushReplacementNamed(context, '/home'); // Chuyển hướng đến trang user
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent.shade400, // Matches gradient
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Đăng Nhập',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/auth/register'),
                                  child: Text(
                                    'Chưa có tài khoản? Đăng ký ngay',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blueAccent.shade400, // Matches button
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}