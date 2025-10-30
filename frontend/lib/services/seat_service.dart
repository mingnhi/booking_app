import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/seat.dart';

class SeatService extends ChangeNotifier {
  final String baseUrl = 'http://127.0.0.1:3000';
  final _storage = FlutterSecureStorage();
  bool isLoading = false;
  List<Seat> seats = [];

  Future<void> fetchSeats() async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/seats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        seats = (jsonDecode(response.body) as List).map((e) => Seat.fromJson(e)).toList();
      } else {
        throw Exception('Failed to fetch seats: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching seats: $e');
      seats = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSeatsByTripId(String tripId) async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/seats/trip/$tripId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        seats = data.map((e) => Seat.fromJson(e)).toList();
        print('Fetched seats for tripId $tripId: $seats');
      } else {
        throw Exception('Failed to fetch seats by tripId: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching seats by tripId: $e');
      seats = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableSeatsByTripId(String tripId) async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/seats/available/$tripId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        seats = (data['seats'] as List).map((e) => Seat.fromJson(e)).toList();
        print('Fetched available seats for tripId $tripId: ${seats.length} seats');
      } else {
        throw Exception('Failed to fetch available seats: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching available seats by tripId: $e');
      seats = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Seat?> createSeat(Seat seat) async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/seats'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(seat.toJson()),
      );
      if (response.statusCode == 200) {
        return Seat.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create seat: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating seat: $e');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Seat?> updateSeat(String id, Seat seat) async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/seats/$id'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(seat.toJson()),
      );
      if (response.statusCode == 200) {
        return Seat.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update seat: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating seat: $e');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSeat(String id) async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/seats/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting seat: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}