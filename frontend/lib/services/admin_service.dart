import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class AdminService extends ChangeNotifier {
  final String baseUrl = 'https://booking-app-1-bzfs.onrender.com';
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _error;
  late Dio _dio;

  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminService() {
    _dio = Dio();
  }

  Future<String?> _getValidToken() async {
    var token = await _storage.read(key: 'accessToken');
    if (token == null) {
      throw Exception('Không tìm thấy token. Vui lòng đăng nhập lại.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/check-token'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) {
        throw Exception('Không tìm thấy refresh token.');
      }

      final refreshResponse = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (refreshResponse.statusCode == 200) {
        final newToken = jsonDecode(refreshResponse.body)['accessToken'];
        await _storage.write(key: 'accessToken', value: newToken);
        return newToken;
      } else {
        throw Exception('Không thể refresh token.');
      }
    }

    return token;
  }

  Future<List<dynamic>> getTrips() async {
    _isLoading = true;
    _error = null;
    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/trip'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getTrips: $e');
      rethrow; // Ném lại lỗi để widget xử lý
    }
  }

  Future<dynamic> getTripDetail(String tripId) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/trip/$tripId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load trip details: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getTripDetail: $e');
      rethrow;
    }
  }

  Future<dynamic> updateTrip(
    String tripId,
    Map<String, dynamic> tripData,
  ) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling PUT $baseUrl/admin/trip/$tripId with data: $tripData');

      final response = await http.put(
        Uri.parse('$baseUrl/admin/trip/$tripId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(tripData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Failed to update trip: ${response.statusCode} - ${errorBody['message'] ?? response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in updateTrip: $e');
      rethrow;
    }
  }

  Future<bool> deleteTrip(String tripId) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling DELETE $baseUrl/admin/trip/$tripId');

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/trip/$tripId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return true;
      } else {
        throw Exception('Failed to delete trip: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in deleteTrip: $e');
      rethrow;
    }
  }

  Future<dynamic> createTrip(Map<String, dynamic> tripData) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling POST $baseUrl/admin/trip with data: $tripData');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/trip'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(tripData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create trip: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in createTrip: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getUsers() async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getUsers: $e');
      rethrow;
    }
  }

  Future<void> updateUser(Map<String, dynamic> updatedUser) async {
    final String userId = updatedUser['_id'];
    final token = await _getValidToken();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updatedUser),
    );

    if (response.statusCode != 200) {
      throw Exception('Cập nhật người dùng thất bại');
    }
  }

  Future<List<dynamic>> getLocations() async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getLocations: $e');
      rethrow;
    }
  }

  Future<bool> deleteUser(String userID) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling DELETE $baseUrl/admin/users/$userID');

      final response = await http.delete(
        Uri.parse(' $baseUrl/admin/users/$userID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return true;
      } else {
        throw Exception('Failed to delete location: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in deleteLocation: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getTickets() async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/ticket'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getTickets: $e');
      rethrow;
    }
  }

  Future<dynamic> getTicketDetail(String ticketId) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/ticket/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load ticket details: ${response.statusCode}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getTicketDetail: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getSeats() async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/seat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load seats: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getSeats: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateTicketStatus(
    String ticketId,
    String status,
  ) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling PUT $baseUrl/admin/ticket/$ticketId with status: $status');

      final response = await http.put(
        Uri.parse('$baseUrl/admin/ticket/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'ticket_status': status}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Failed to update ticket status: ${response.statusCode} - ${errorBody['message'] ?? response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in updateTicketStatus: $e');
      rethrow;
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/ticket/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
      } else {
        throw Exception('Failed to delete ticket: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in deleteTicket: $e');
      rethrow;
    }
  }

  Future<dynamic> getLocationDetail(String locationId) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/location/$locationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load location details: ${response.statusCode}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getLocationDetail: $e');
      rethrow;
    }
  }

  Future<dynamic> createLocation(Map<String, dynamic> locationData) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling POST $baseUrl/admin/location with data: $locationData');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(locationData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create location: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in createLocation: $e');
      rethrow;
    }
  }

  Future<dynamic> updateLocation(
    String locationId,
    Map<String, dynamic> locationData,
  ) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print(
        'Calling PUT $baseUrl/admin/location/$locationId with data: $locationData',
      );

      final response = await http.put(
        Uri.parse('$baseUrl/admin/location/$locationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(locationData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Failed to update location: ${response.statusCode} - ${errorBody['message'] ?? response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in updateLocation: $e');
      rethrow;
    }
  }

  Future<bool> deleteLocation(String locationId) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling DELETE $baseUrl/admin/location/$locationId');

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/location/$locationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return true;
      } else {
        throw Exception('Failed to delete location: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in deleteLocation: $e');
      rethrow;
    }
  }

  Future<dynamic> createSeat(Map<String, dynamic> seatData) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling POST $baseUrl/seats with data: $seatData');

      final response = await http.post(
        Uri.parse('$baseUrl/seats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(seatData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create seat: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in createSeat: $e');
      rethrow;
    }
  }

  Future<dynamic> updateSeat(
    String seatId,
    Map<String, dynamic> seatData,
  ) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling PUT $baseUrl/seats/$seatId with data: $seatData');

      final response = await http.put(
        Uri.parse('$baseUrl/seats/$seatId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(seatData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Failed to update seat: ${response.statusCode} - ${errorBody['message'] ?? response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in updateSeat: $e');
      rethrow;
    }
  }

  Future<bool> deleteSeat(String seatId) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling DELETE $baseUrl/admin/seat/$seatId');

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/seat/$seatId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return true;
      } else {
        throw Exception('Failed to delete seat: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in deleteSeat: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getPayments() async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load payments: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getPayments: $e');
      rethrow;
    }
  }

  Future<dynamic> getPaymentById(String paymentId) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/payments/$paymentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load payment details: ${response.statusCode}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getPaymentById: $e');
      rethrow;
    }
  }

  Future<dynamic> updatePaymentStatus(String paymentId, String status) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print(
        'Calling PATCH $baseUrl/admin/payments/$paymentId with status: $status',
      );

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/payments/$paymentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'payment_status': status}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Failed to update payment status: ${response.statusCode} - ${errorBody['message'] ?? response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in updatePaymentStatus: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getVehicles() async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/vehicle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in getVehicles: $e');
      rethrow;
    }
  }

  Future<dynamic> createVehicle(Map<String, dynamic> vehicleData) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling POST $baseUrl/admin/vehicles with data: $vehicleData');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(vehicleData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create vehicle: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in createVehicle: $e');
      rethrow;
    }
  }

  Future<dynamic> updateVehicle(
    String vehicleId,
    Map<String, dynamic> vehicleData,
  ) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print(
        'Calling PUT $baseUrl/admin/vehicles/$vehicleId with data: $vehicleData',
      );

      final response = await http.put(
        Uri.parse('$baseUrl/admin/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(vehicleData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Failed to update vehicle: ${response.statusCode} - ${errorBody['message'] ?? response.body}',
        );
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in updateVehicle: $e');
      rethrow;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    _isLoading = true;
    _error = null;

    try {
      final token = await _getValidToken();
      print('Calling DELETE $baseUrl/admin/vehicles/$vehicleId');

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _isLoading = false;
        return true;
      } else {
        throw Exception('Failed to delete vehicle: ${response.statusCode}');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error in deleteVehicle: $e');
      rethrow;
    }
  }
}
