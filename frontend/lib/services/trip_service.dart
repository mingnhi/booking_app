import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/screens/auth/auth_storage.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';

class TripService extends ChangeNotifier {
  final String baseUrl = 'http://167.172.78.63:3000';
  final storage = AuthStorage();
  bool isLoading = false;
  List<Trip> trips = [];
  String? errorMessage;
  List<Map<String, dynamic>> recentSearches = [];

  void safeNotifyListeners() {
    try {
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error in TripService notifyListeners: $e');
    }
  }

  void addRecentSearch(String departureId, String arrivalId, DateTime date,
      {String? tripId}) {
    recentSearches.insert(0, {
      'departureId': departureId,
      'arrivalId': arrivalId,
      'date': date,
      'tripId': tripId,
    });
    if (recentSearches.length > 5) recentSearches.removeLast();
    safeNotifyListeners();
  }

  Future<void> fetchTrips({bool allowUnauthenticated = false}) async {
    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();

    try {
      String? token;
      if (!allowUnauthenticated) {
        token = await storage.readToken('accessToken');
        if (token == null) {
          throw Exception('No access token found');
        }
      }

      final response = await http.get(
        Uri.parse('$baseUrl/trip'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        trips =
            data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception(
            'Failed to fetch trips: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching trips: $e');
      errorMessage = 'Không thể tải danh sách chuyến đi.';
      trips = [];
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<List<Trip>> searchTrips({
    String? departureLocation,
    String? arrivalLocation,
    DateTime? departureTime,
    bool allowUnauthenticated = false, // Thêm tham số
  }) async {
    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();

    try {
      String? token;
      if (!allowUnauthenticated) {
        token = await storage.readToken('accessToken');
        if (token == null) {
          throw Exception('No access token found');
        }
      }

      final body = {
        if (departureLocation != null) 'departure_location': departureLocation,
        if (arrivalLocation != null) 'arrival_location': arrivalLocation,
        if (departureTime != null)
          'departure_time': DateFormat('yyyy-MM-dd').format(departureTime),
      };

      if (kDebugMode) print('Search trips request body: $body');
      final response = await http.post(
        Uri.parse('$baseUrl/trip/search'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (kDebugMode)
        print(
            'Search trips response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        trips =
            data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
        return trips;
      } else {
        throw Exception(
            'Failed to search trips: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error searching trips: $e');
      errorMessage = 'Không thể tìm kiếm chuyến đi.';
      return [];
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<Trip?> fetchTripById(String tripId,
      {bool allowUnauthenticated = false}) async {
    if (tripId.isEmpty) {
      errorMessage = 'Trip ID cannot be empty';
      safeNotifyListeners();
      return null;
    }
    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();

    try {
      String? token;
      if (!allowUnauthenticated) {
        token = await storage.readToken('accessToken');
        if (token == null) {
          throw Exception('No access token found');
        }
      }

      if (kDebugMode) print('Fetching trip with ID: $tripId');
      final response = await http.get(
        Uri.parse(
            '$baseUrl/admin/trip/$tripId'), // Sửa endpoint từ /admin/trip/:id thành /trip/:id
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode)
        print('Fetch trip response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final trip = Trip.fromJson(data);
        final index = trips.indexWhere((t) => t.id == tripId);
        if (index != -1) {
          trips[index] = trip;
        } else {
          trips.add(trip);
        }
        return trip;
      } else {
        throw Exception(
            'Failed to fetch trip: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching trip by ID: $e');
      errorMessage = 'Không thể tải thông tin chuyến đi.';
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<Trip?> createTrip(Trip trip) async {
    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();
    final token = await storage.readToken('accessToken');
    if (token == null) {
      errorMessage = 'No access token found';
      isLoading = false;
      safeNotifyListeners();
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/trip'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(trip.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final newTrip = Trip.fromJson(data);
        trips.add(newTrip);
        return newTrip;
      } else {
        throw Exception(
            'Failed to create trip: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error creating trip: $e');
      errorMessage = 'Error creating trip: $e';
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }
}
