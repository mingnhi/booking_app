import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      print("💾 Saved $key to SharedPreferences (Web)");
    } else {
      await _storage.write(key: key, value: value);
      print("🔐 Saved $key to SecureStorage (Mobile)");
    }
  }

  Future<String?> readToken(String key) async {
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

  Future<void> deleteToken(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _storage.delete(key: key);
    }
  }

  Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      print("💾 [write] Saved $key to SharedPreferences (Web)");
    } else {
      await _storage.write(key: key, value: value);
      print("🔐 [write] Saved $key to SecureStorage (Mobile)");
    }
  }
}
