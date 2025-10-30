import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/location.dart';

class LocationService extends ChangeNotifier {
  final String baseUrl = 'http://127.0.0.1:3000';
  final _storage = FlutterSecureStorage();
  bool isLoading = false;
  List<Location> locations = [];
  String? errorMessage;

  void safeNotifyListeners() {
    try {
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error in LocationService notifyListeners: $e');
    }
  }

  Future<void> fetchLocations({bool allowUnauthenticated = false}) async {
    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();

    try {
      String? token;
      if (!allowUnauthenticated) {
        token = await _storage.read(key: 'accessToken');
        if (token == null) {
          throw Exception('No access token found');
        }
      }

      final response = await http.get(
        Uri.parse('$baseUrl/location'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        locations = data.map((e) => Location.fromJson(e)).toList();
      } else {
        throw Exception('Failed to fetch locations: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching locations: $e');
      errorMessage = 'Không thể tải danh sách địa điểm.';
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<Location?> createLocation(String location) async {
    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();
    final token = await _storage.read(key: 'accessToken');
    if (token == null) {
      errorMessage = 'No access token found';
      isLoading = false;
      safeNotifyListeners();
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'location': location}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final newLocation = Location.fromJson(jsonDecode(response.body));
        locations.add(newLocation);
        return newLocation;
      } else {
        errorMessage =
        'Failed to create location: ${response.statusCode} - ${response.body}';
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Error creating location: $e');
      errorMessage = 'Error creating location: $e';
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<Location?> updateLocation(String id, String location) async {
    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();
    final token = await _storage.read(key: 'accessToken');
    if (token == null) {
      errorMessage = 'No access token found';
      isLoading = false;
      safeNotifyListeners();
      return null;
    }
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/location/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'location': location}),
      );
      if (response.statusCode == 200) {
        final updatedLocation = Location.fromJson(jsonDecode(response.body));
        final index = locations.indexWhere((loc) => loc.id == id);
        if (index != -1) locations[index] = updatedLocation;
        return updatedLocation;
      } else {
        errorMessage =
        'Failed to update location: ${response.statusCode} - ${response.body}';
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Error updating location: $e');
      errorMessage = 'Error updating location: $e';
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<bool> deleteLocation(String id) async {
    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();
    final token = await _storage.read(key: 'accessToken');
    if (token == null) {
      errorMessage = 'No access token found';
      isLoading = false;
      safeNotifyListeners();
      return false;
    }
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/location/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        locations.removeWhere((loc) => loc.id == id);
        return true;
      } else {
        errorMessage =
        'Failed to delete location: ${response.statusCode} - ${response.body}';
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting location: $e');
      errorMessage = 'Error deleting location: $e';
      return false;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }
}