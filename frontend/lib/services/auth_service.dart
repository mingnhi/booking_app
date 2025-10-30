import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/auth.dart';

class AuthService extends ChangeNotifier {
  final String baseUrl = 'http://167.172.78.63:3000';
  final _storage = FlutterSecureStorage();
  bool isLoading = false;
  String? errorMessage;
  User? currentUser;

  AuthService() {
    // Khôi phục trạng thái đăng nhập khi khởi tạo
    _restoreSession();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<void> _restoreSession() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null) {
        // Thử lấy profile với token hiện tại
        final user = await getProfile();
        if (user != null) {
          currentUser = user;
          notifyListeners();
        } else {
          // Nếu token không hợp lệ, thử làm mới token
          final loginResponse = await refreshToken();
          if (loginResponse != null && loginResponse.user != null) {
            currentUser = loginResponse.user;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error restoring session: $e');
    }
  }

  Future<LoginResponse?> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'accessToken', value: data['accessToken']);
        await _storage.write(key: 'refreshToken', value: data['refresh_token']);
        final loginResponse = LoginResponse.fromJson(data);
        currentUser = loginResponse.user;
        notifyListeners();
        return loginResponse;
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error logging in: $e');
      errorMessage = e.toString().contains('Login failed')
          ? jsonDecode(e.toString().split(' - ')[1])['message']
          : e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isAdmin() {
    return currentUser?.role == 'admin';
  }

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
        return true;
      } else {
        throw Exception('Registration failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error registering: $e');
      errorMessage = e.toString().contains('Registration failed')
          ? jsonDecode(e.toString().split(' - ')[1])['message']
          : e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> getProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    if (token == null) {
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
        print('Profile Response: ${response.body}');
        currentUser = User.fromJson(jsonDecode(response.body));
        notifyListeners();
        return currentUser;
      } else {
        throw Exception('Failed to get profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting profile: $e');
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<LoginResponse?> refreshToken() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null) {
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
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'accessToken', value: data['accessToken']);
        await _storage.write(key: 'refreshToken', value: data['refresh_token']);
        final loginResponse = LoginResponse.fromJson(data);
        if (loginResponse.user != null) {
          currentUser = loginResponse.user;
          notifyListeners();
        }
        return loginResponse;
      } else {
        throw Exception('Failed to refresh token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error refreshing token: $e');
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    currentUser = null;
    notifyListeners();
  }
}