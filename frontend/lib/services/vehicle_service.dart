import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/vehicle.dart';

class VehicleService extends ChangeNotifier {
  final _storage = FlutterSecureStorage();
  List<Vehicle> vehicles = [];
  bool isLoading = false;
  String? error;

  final String baseUrl =
      'https://booking-app-1-bzfs.onrender.com'; // API server URL

  Future<void> fetchVehicles() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw Exception('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/vehicle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        vehicles = data.map((item) => Vehicle.fromJson(item)).toList();
        isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      print('Error in fetchVehicles: $e');
    }
  }

  Future<Vehicle?> createVehicle(Vehicle vehicle) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw Exception('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/vehicle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newVehicle = Vehicle.fromJson(data);
        vehicles.add(newVehicle);
        isLoading = false;
        notifyListeners();
        return newVehicle;
      } else {
        throw Exception('Failed to create vehicle: ${response.statusCode}');
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      print('Error in createVehicle: $e');
      return null;
    }
  }

  Future<Vehicle?> updateVehicle(String id, Vehicle vehicle) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw Exception('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/vehicle/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedVehicle = Vehicle.fromJson(data);

        // Cập nhật danh sách vehicles
        final index = vehicles.indexWhere((v) => v.id == id);
        if (index != -1) {
          vehicles[index] = updatedVehicle;
        }

        isLoading = false;
        notifyListeners();
        return updatedVehicle;
      } else {
        throw Exception('Failed to update vehicle: ${response.statusCode}');
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      print('Error in updateVehicle: $e');
      return null;
    }
  }

  Future<bool> deleteVehicle(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw Exception('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Xóa vehicle khỏi danh sách
        vehicles.removeWhere((v) => v.id == id);
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to delete vehicle: ${response.statusCode}');
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      print('Error in deleteVehicle: $e');
      return false;
    }
  }

  // Phương thức để lấy thông tin vehicle từ ID
  Vehicle? getVehicleById(String id) {
    try {
      return vehicles.firstWhere((vehicle) => vehicle.id == id);
    } catch (e) {
      print('Vehicle not found: $e');
      return null;
    }
  }
}
