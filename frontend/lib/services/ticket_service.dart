import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/ticket.dart';

class TicketService extends ChangeNotifier {
  final String baseUrl = 'http://127.0.0.1:3000';
  final _storage = FlutterSecureStorage();
  bool isLoading = false;
  List<Ticket> tickets = [];
  String? errorMessage;

  Future<void> fetchTickets() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    if (token == null) throw Exception('No access token found');
    try {
      print('Gửi yêu cầu GET đến: $baseUrl/tickets/mytickets');
      print('Token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/tickets/mytickets'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('Phản hồi: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        tickets = data.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Lấy danh sách ticket thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi lấy danh sách ticket: $e');
      tickets = [];
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Ticket?> createTicket(Map<String, dynamic> ticketData) async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    if (token == null) throw Exception('No access token found');
    try {
      print('Creating ticket with data: $ticketData');
      final response = await http.post(
        Uri.parse('$baseUrl/tickets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(ticketData),
      );
      print('Create ticket response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final newTicket = Ticket.fromJson(data);
        tickets.add(newTicket);
        return newTicket;
      } else {
        throw Exception('Tạo ticket thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi tạo ticket: $e');
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Ticket?> updateTicket(String id, Map<String, dynamic> ticketData) async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    if (token == null) throw Exception('No access token found');
    try {
      print('Updating ticket $id with data: $ticketData');
      final response = await http.put(
        Uri.parse('$baseUrl/tickets/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(ticketData),
      );
      print('Update ticket response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final updatedTicket = Ticket.fromJson(data);
        final index = tickets.indexWhere((ticket) => ticket.id == id);
        if (index != -1) {
          tickets[index] = updatedTicket;
        }
        return updatedTicket;
      } else {
        throw Exception('Cập nhật ticket thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi cập nhật ticket: $e');
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTicket(String id) async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    if (token == null) throw Exception('No access token found');
    try {
      print('Deleting ticket $id');
      final response = await http.delete(
        Uri.parse('$baseUrl/tickets/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('Delete ticket response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        tickets.removeWhere((ticket) => ticket.id == id);
        return true;
      } else {
        throw Exception('Xóa ticket thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi xóa ticket: $e');
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Ticket?> fetchTicketById(String id) async {
    isLoading = true;
    notifyListeners();
    final token = await _storage.read(key: 'accessToken');
    if (token == null) throw Exception('No access token found');
    try {
      print('Gửi yêu cầu GET đến: $baseUrl/tickets/$id');
      final response = await http.get(
        Uri.parse('$baseUrl/tickets/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('Phản hồi: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final ticket = Ticket.fromJson(data);
        final index = tickets.indexWhere((t) => t.id == id);
        if (index != -1) {
          tickets[index] = ticket;
        } else {
          tickets.add(ticket);
        }
        return ticket;
      } else {
        throw Exception('Lấy ticket thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi lấy ticket theo id: $e');
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}