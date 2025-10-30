import 'package:flutter/material.dart';
import 'package:frontend/services/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final String ticketId;
  final double amount;

  const PaymentScreen({Key? key, required this.ticketId, required this.amount})
      : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? orderId;
  String? paypalPaymentId;
  String? captureId;
  Future<void> _startPaypalPayment() async {
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    try {
      final orderData = await paymentService.createPayPalOrder(
        amount: widget.amount,
      );

      if (orderData == null) {
        throw Exception('Không thể tạo đơn hàng PayPal');
      }

      final links = orderData['links'];
      if (links == null || links.isEmpty) {
        throw Exception('Không tìm thấy liên kết thanh toán');
      }

      final approveLink = links.firstWhere(
            (link) => link['rel'] == 'approve',
        orElse: () => null,
      );

      if (approveLink == null) {
        throw Exception('Không tìm thấy liên kết thanh toán');
      }

      final approveUrl = approveLink['href'];

      setState(() {
        orderId = orderData['id'];
      });

      if (await canLaunchUrl(Uri.parse(approveUrl))) {
        await launchUrl(
          Uri.parse(approveUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Không thể mở liên kết PayPal');
      }
    } catch (e) {
      print('Lỗi khi tạo đơn hàng PayPal: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tạo thanh toán: $e')));
    }
  }


  Future<void> _confirmPayment() async {
    if (orderId == null) return;

    final paymentService = Provider.of<PaymentService>(context, listen: false);
    try {
      final captureData = await paymentService.captureOrder(orderId!);

      if (captureData == null ||
          captureData['purchase_units'] == null ||
          captureData['purchase_units'][0]['payments'] == null ||
          captureData['purchase_units'][0]['payments']['captures'] == null) {
        throw Exception('Dữ liệu xác nhận thanh toán không hợp lệ');
      }

      final id =
      captureData['purchase_units'][0]['payments']['captures'][0]['id'];
      final status = captureData['status'] ?? 'unknown';

      setState(() {
        captureId = id;
      });
      print('captureId: $captureId');
      await paymentService.createPayment(
        ticketId: widget.ticketId,
        orderId: orderId!,
        captureId: captureId!,
        amount: widget.amount,
        paymentMethod: 'paypal',
        paymentStatus: status,
      );
      print('Sending payment to backend:');
      print('ticketId: ${widget.ticketId}');
      print('orderId: $orderId');
      print('amount: ${widget.amount}');
      print('paymentMethod: paypal');
      print('status: $status');


      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Thanh toán thành công!')));

      Navigator.pop(context); // hoặc chuyển sang màn hình khác
    } catch (e) {
      print('Lỗi khi capture đơn hàng: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi xác nhận thanh toán')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thanh toán PayPal')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Tổng thanh toán: \$${widget.amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _startPaypalPayment,
              icon: Icon(Icons.payment),
              label: Text('Thanh toán với PayPal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
            ),
            if (orderId != null) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _confirmPayment,
                child: Text('Xác nhận đã thanh toán'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
