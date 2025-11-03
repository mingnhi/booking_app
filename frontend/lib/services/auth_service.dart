import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/screens/auth/auth_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/auth.dart';

class AuthService extends ChangeNotifier {
  final String baseUrl = 'http://139.59.247.233:3000';
  final _storage = const FlutterSecureStorage();
  final storage = AuthStorage();

  bool isLoading = false;
  String? errorMessage;
  User? currentUser;

  // Khởi tạo
  AuthService() {
    _restoreSession();
  }

  // 🧠 Tự động chọn nơi lưu token
  Future<void> _saveToken(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      print("💾 Saved $key to SharedPreferences (Web)");
    } else {
      await _storage.write(key: key, value: value);
      print("💾 Saved $key to SecureStorage (Mobile)");
    }
  }

  Future<String?> _readToken(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(key);
      print("📦 Read $key from SharedPreferences (Web): $token");
      return token;
    } else {
      final token = await _storage.read(key: key);
      print("📦 Read $key from SecureStorage (Mobile): $token");
      return token;
    }
  }

  Future<String?> getToken() async {
    final token = await _readToken('accessToken');
    return token;
  }

  Future<void> _deleteToken(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _storage.delete(key: key);
    }
  }

  // 🔁 Khôi phục phiên đăng nhập nếu có token
  Future<void> _restoreSession() async {
    try {
      final token = await _readToken('accessToken');
      if (token != null && token.isNotEmpty) {
        final user = await getProfile();
        if (user != null) {
          currentUser = user;
          notifyListeners();
        } else {
          final refreshed = await refreshToken();
          if (refreshed?.user != null) {
            currentUser = refreshed!.user;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('⚠️ Error restoring session: $e');
    }
  }

  // 🔑 Đăng nhập
  Future<LoginResponse?> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/auth/login');
      print('🔹 Sending login request to: $url');
      print('🔹 Payload: email=$email, password=$password');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('🔹 Raw response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        await _saveToken('accessToken', data['accessToken']);
        await _saveToken(
          'refreshToken',
          data['refresh_token'] ?? data['refreshToken'],
        );

        final loginResponse = LoginResponse.fromJson(data);
        currentUser = loginResponse.user;
        print('✅ Logged in user: ${currentUser?.email}');
        notifyListeners();
        return loginResponse;
      } else {
        throw Exception(
          'Login failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stack) {
      print('❌ Error logging in: $e');
      print(stack);

      try {
        if (e.toString().contains('Login failed')) {
          final body = e.toString().split(' - ')[1];
          final decoded = jsonDecode(body);
          errorMessage = decoded['message'] ?? 'Đăng nhập thất bại.';
        } else {
          errorMessage = e.toString();
        }
      } catch (_) {
        errorMessage = 'Đăng nhập thất bại, vui lòng thử lại.';
      }

      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 👤 Kiểm tra role admin
  bool isAdmin() {
    return currentUser?.role == 'admin';
  }

  // 📝 Đăng ký tài khoản mới
  Future<bool> register(RegisterRequest request) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Register success');
        return true;
      } else {
        throw Exception(
            'Registration failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error registering: $e');
      errorMessage = e.toString().contains('Registration failed')
          ? jsonDecode(e.toString().split(' - ')[1])['message']
          : e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 👥 Lấy thông tin profile hiện tại
  Future<User?> getProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final token = await _readToken('accessToken');
    if (token == null || token.isEmpty) {
      errorMessage = 'No access token found';
      isLoading = false;
      notifyListeners();
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print('✅ Profile Response: ${response.body}');
        currentUser = User.fromJson(jsonDecode(response.body));
        notifyListeners();
        return currentUser;
      } else if (response.statusCode == 401) {
        print('⚠️ Token expired, attempting refresh...');
        await refreshToken();
      } else {
        throw Exception(
          'Failed to get profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error getting profile: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return null;
  }

  // 🔄 Làm mới token
  Future<LoginResponse?> refreshToken() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final refreshToken = await _readToken('refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      print('⚠️ No refresh token found.');
      errorMessage = 'No refresh token found';
      isLoading = false;
      notifyListeners();
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      print(
          '🔄 Refresh token response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken('accessToken', data['accessToken']);
        await _saveToken('refreshToken', data['refresh_token']);
        final refreshed = LoginResponse.fromJson(data);
        currentUser = refreshed.user;
        notifyListeners();
        return refreshed;
      } else {
        throw Exception(
          'Failed to refresh token: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _deleteToken('accessToken');
    await _deleteToken('refreshToken');
    currentUser = null;
    print('Logged out successfully.');
    notifyListeners();
  }
}
