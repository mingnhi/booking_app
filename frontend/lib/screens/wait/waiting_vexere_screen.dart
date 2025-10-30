import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class WaitingVexereScreen extends StatefulWidget {
  const WaitingVexereScreen({super.key});

  @override
  _WaitingVexereScreenState createState() => _WaitingVexereScreenState();
}

class _WaitingVexereScreenState extends State<WaitingVexereScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    // Khởi tạo AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Hiệu ứng fade-in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Hiệu ứng scale cho logo
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Bắt đầu animation
    _animationController.forward();

    // Kiểm tra token và chuyển hướng sau 4 giây
    Timer(const Duration(seconds: 4), () async {
      if (mounted) {
        final token = await _storage.read(key: 'accessToken');
        Navigator.pushReplacementNamed(
          context,
          token != null ? '/home' : '/auth/login',
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A73E8),
              Color.fromARGB(255, 131, 183, 252),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/vexere_logo.png',
                  width: 300,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Khởi đầu suôn sẻ cho hành trình trọn vẹn',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      const Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}