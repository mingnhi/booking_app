import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/auth.dart';
import '../../services/auth_service.dart';
import '../home/customer_nav_bar.dart'; // Import CustomNavBar

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  int _selectedIndex = 3; // Current index of the navigation bar (Tài khoản)
  bool _isEditing = true; // Default to editable state as per the image
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController; // Added for date of birth

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0052CC), // Match the AppBar color
      statusBarIconBrightness: Brightness.light,
    ));

    Future.microtask(() {
      if (mounted) {
        _animationController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        );
        _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
        );
        _animationController!.forward();
      }
    });

    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController(); // Initialize date of birth controller

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.getProfile().then((_) {
        if (authService.currentUser != null) {
          _fullNameController.text = authService.currentUser!.fullName;
          _emailController.text = authService.currentUser!.email;
          _phoneController.text = authService.currentUser!.phoneNumber ?? '';
          _dobController.text = '03/07/2004'; // Static value to match the image; adjust as needed
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/trip/search');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/tickets');
        break;
      case 3:
        break;
    }
  }

  Future<void> _updateProfile(AuthService authService) async {
    final url = Uri.parse('${authService.baseUrl}/users/${authService.currentUser!.id}');
    final token = await authService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy token đăng nhập')),
      );
      return;
    }

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'full_name': _fullNameController.text,
          'email': _emailController.text,
          'phone_number': _phoneController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        authService.currentUser = User.fromJson(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!')),
        );
        setState(() {
          _isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _logout(AuthService authService) async {
    try {
      await authService.logout();
      Navigator.pushReplacementNamed(context, '/auth/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng xuất thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match the white background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamed(
            context,
            '/tickets',
          )
        ),
        title: Text(
          'Thông tin tài khoản',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final authService = Provider.of<AuthService>(context, listen: false);
              _logout(authService);
            },
            child: Text(
              'Đăng xuất',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline, // thêm dòng này để gạch chân
                decorationColor: Colors.white,
                decorationThickness: 1,
              ),
            ),
          )
        ],
        backgroundColor: Color(0xFF2474E5), // Match the dark blue AppBar
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.white, // Ensure white background
        child: SafeArea(
          top: false,
          bottom: false,
          child: Consumer<AuthService>(
            builder: (context, authService, _) {
              if (authService.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (authService.errorMessage != null) {
                return Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          authService.errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/auth/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003087),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Đăng Nhập Lại',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (authService.currentUser == null) {
                return Center(
                  child: Text(
                    'Không thể tải thông tin người dùng.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }
              if (_fadeAnimation == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Full Name Field
                      _buildEditableField(
                        label: 'Họ và tên',
                        controller: _fullNameController,
                        required: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Phone Number Field
                      Row(
                        children: [
                          Expanded(
                            child: _buildEditableField(
                              label: 'Số điện thoại',
                              controller: _phoneController,
                              required: true,
                              validator: (value) {
                                if (value != null && value.isNotEmpty && !RegExp(r'^\d{9}$').hasMatch(value)) {
                                  return 'Số điện thoại phải có 9 chữ số';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Email Field
                      _buildEditableField(
                        label: 'Email',
                        controller: _emailController,
                        required: true,
                        validator: (value) {
                          if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Vui lòng nhập email hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_fullNameController.text.isEmpty ||
                                _emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin!')),
                              );
                              return;
                            }
                            _updateProfile(authService);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003087), // Dark blue
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Lưu',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5), // Light grey background
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF003087), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon,
          ),
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
          ),
          validator: validator,
        ),
      ],
    );
  }
}