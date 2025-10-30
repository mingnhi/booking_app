import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/auth.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
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
    _fullNameController.dispose();
    _phoneNumberController.dispose();
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
                      'Đăng Ký',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tạo tài khoản để bắt đầu hành trình',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 32),
                    Card(
                      elevation: 10,
                      shadowColor: Colors.blueAccent.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.blueAccent.shade100.withOpacity(0.5), width: 1),
                      ),
                      color: Colors.white.withOpacity(0.95),
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
                                  controller: _fullNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Họ và Tên',
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.blueAccent.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: 'Nhập họ và tên của bạn',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.blueGrey.shade200,
                                    ),
                                    prefixIcon: Icon(Icons.person, color: Colors.blueAccent.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade100, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade400, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.blue.shade50.withOpacity(0.5),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: Colors.blueGrey.shade800,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 20),
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.blueAccent.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: 'Nhập email của bạn',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.blueGrey.shade200,
                                    ),
                                    prefixIcon: Icon(Icons.email, color: Colors.blueAccent.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade100, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade400, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.blue.shade50.withOpacity(0.5),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.poppins(
                                    color: Colors.blueGrey.shade800,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 20),
                                TextField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Mật Khẩu',
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.blueAccent.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: 'Nhập mật khẩu của bạn',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.blueGrey.shade200,
                                    ),
                                    prefixIcon: Icon(Icons.lock, color: Colors.blueAccent.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade100, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade400, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.blue.shade50.withOpacity(0.5),
                                  ),
                                  obscureText: true,
                                  style: GoogleFonts.poppins(
                                    color: Colors.blueGrey.shade800,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 20),
                                TextField(
                                  controller: _phoneNumberController,
                                  decoration: InputDecoration(
                                    labelText: 'Số Điện Thoại',
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.blueAccent.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: 'Nhập số điện thoại của bạn',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.blueGrey.shade200,
                                    ),
                                    prefixIcon: Icon(Icons.phone, color: Colors.blueAccent.shade400),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade100, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.blueAccent.shade400, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.blue.shade50.withOpacity(0.5),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.poppins(
                                    color: Colors.blueGrey.shade800,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 24),
                                authService.isLoading
                                    ? CircularProgressIndicator()
                                    : ElevatedButton(
                                  onPressed: () async {
                                    final request = RegisterRequest(
                                      fullName: _fullNameController.text,
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                      phoneNumber: _phoneNumberController.text,
                                    );
                                    final success = await authService.register(request);
                                    if (success) {
                                      Navigator.pushReplacementNamed(context, '/auth/login');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent.shade400,
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
                                      'Đăng Ký',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/auth/login'),
                                  child: Text(
                                    'Đã có tài khoản? Đăng nhập ngay',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blueAccent.shade400,
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