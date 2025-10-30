import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/config/paypal_config.dart';
import 'package:frontend/models/payment.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
// import '../models/payment_model.dart';

class PaymentService extends ChangeNotifier {
  final String baseUrl = "https://booking-app-1-bzfs.onrender.com";
  final _storage = FlutterSecureStorage();
  bool isLoading = false;
  List<Payment> _payments = [];
  String? lastExecuteUrl;
  List<Payment> get payments => _payments;

  Future<void> fetchPayments() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('$baseUrl/payment/mypayment'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Dữ liệu nhận được từ API: $data');
      _payments = data.map((item) => Payment.fromJson(item)).toList();
      notifyListeners(); // thông báo thay đổi để UI rebuild
    } else {
      print(
        'Lỗi khi fetch payments: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Payment? getPaymentByTicketId(String ticketId) {
    try {
      return _payments.firstWhere((payment) => payment.ticketId == ticketId);
    } catch (e) {
      return null;
    }
  }

  Future<String> getAccessToken() async {
    final response = await http.post(
      Uri.parse('${PayPalConfig.baseUrl}/v1/oauth2/token'),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${PayPalConfig.clientId}:${PayPalConfig.secret}'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to get access token');
    }
  }

  Future<Map<String, dynamic>?> createPayPalOrder({
    required double amount,
  }) async {
    final accessToken = await getAccessToken();

    final response = await http.post(
      Uri.parse('${PayPalConfig.baseUrl}/v2/checkout/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'intent': 'CAPTURE',
        'purchase_units': [
          {
            'amount': {
              'currency_code': 'USD',
              'value': amount.toStringAsFixed(2),
            },
          },
        ],
        'application_context': {
          'return_url': PayPalConfig.returnUrl,
          'cancel_url': PayPalConfig.cancelUrl,
        },
      }),
    );

    print('PayPal Order Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final approveLink = (data['links'] as List<dynamic>).firstWhere(
        (link) => link['rel'] == 'approve',
        orElse: () => null,
      );

      if (approveLink != null && approveLink['href'] != null) {
        final url = approveLink['href'];
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Không thể mở liên kết PayPal');
        }
        return data;
      } else {
        throw Exception('Không tìm thấy liên kết approve từ PayPal');
      }
    } else {
      throw Exception(
        'Lỗi khi tạo thanh toán PayPal: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> createPayment({
    required String ticketId,
    required String orderId,
    required String paymentMethod,
    required double amount,
    required String paymentStatus,
    required String captureId,
  }) async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) throw Exception('Token không tồn tại');

    if (orderId.isEmpty) {
      print('Error: orderId is empty');
      return;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ticket_id': ticketId,
        'order_id': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'capture_id': captureId,
      }),
    );
    if (response.statusCode == 201) {
      print('Payment info sent to backend successfully.');
    } else {
      print(
        'Error sending payment to backend: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>?> captureOrder(String orderId) async {
    final accessToken = await getAccessToken();

    final response = await http.post(
      Uri.parse('${PayPalConfig.baseUrl}/v2/checkout/orders/$orderId/capture'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    print('Capture Order Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Error capturing PayPal order: ${response.body}");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    final accessToken = await getAccessToken();

    final response = await http.get(
      Uri.parse('${PayPalConfig.baseUrl}/v2/checkout/orders/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    print(
      'Get Order Details Response: ${response.statusCode} - ${response.body}',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Error fetching order details: ${response.body}");
      return null;
    }
  }

  Future<Map<String, dynamic>?> refundPayment({
    required String captureId,
    required double amount,
  }) async {
    try {
      final accessToken = await getAccessToken();

      final response = await http.post(
        Uri.parse(
          '${PayPalConfig.baseUrl}/v2/payments/captures/$captureId/refund',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'amount': {
            'value': amount.toStringAsFixed(2),
            'currency_code': 'USD',
          },
        }),
      );

      print('Refund Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Refund failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during refund: $e');
      return null;
    }
  }

  Future<void> refundPaypalPayment({
    required String paymentId,
    required Map<String, dynamic> refundData,
  }) async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) throw Exception('Token không tồn tại');

    final response = await http.put(
      Uri.parse('$baseUrl/payment/refund/$paymentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'paymentId': paymentId,
        'refundData': refundData, // bạn có thể lưu thêm thông tin chi tiết
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('Lưu thông tin hoàn tiền thành công.');
    } else {
      print(
        'Lỗi khi lưu thông tin hoàn tiền: ${response.statusCode} - ${response.body}',
      );
      throw Exception('Failed to save refund info');
    }
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    try {
      // Tìm payment theo ID
      final paymentIndex = _payments.indexWhere((p) => p.id == paymentId);
      if (paymentIndex != -1) {
        _payments[paymentIndex] = _payments[paymentIndex].copyWith(
          paymentStatus: status,
        );
        // Gửi yêu cầu cập nhật lên server (thay bằng API call thực tế)
        // Ví dụ: await api.updatePayment(paymentId, {'payment_status': status});
      }
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái thanh toán: $e');
      rethrow;
    }
  }
}
