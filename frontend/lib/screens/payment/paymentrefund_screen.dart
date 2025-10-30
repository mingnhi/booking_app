
import 'package:flutter/material.dart';
import 'package:frontend/services/payment_service.dart';
import 'package:provider/provider.dart' show Provider;

class RefundScreen extends StatefulWidget {
  final String captureId;
  final String paymentId;
  final double amount;

  const RefundScreen({Key? key, required this.captureId,required this.paymentId, required this.amount})
      : super(key: key);

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  bool isLoading = false;
  String? refundMessage;
  String paymentStatus = 'COMPLETED';

  Future<void> handleRefund() async {
    setState(() {
      isLoading = true;
      refundMessage = null;
    });

    try {
      final paymentService = Provider.of<PaymentService>(
        context,
        listen: false,
      );

      // Gọi API hoàn tiền từ PayPal (và lưu vào backend nếu cần)
      final refundData = await paymentService.refundPayment(
        captureId: widget.captureId,
        amount: widget.amount,
      );

      if (refundData != null) {
        // Gọi API lưu refund vào backend
        await paymentService.refundPaypalPayment(
          paymentId: widget.paymentId,
          refundData: refundData,
        );

        setState(() {
          refundMessage = 'Hoàn tiền thành công!';
        });
      } else {
        setState(() {
          refundMessage = 'Hoàn tiền thất bại!';
        });
      }
    } catch (e) {
      String errorMessage = 'Đã xảy ra lỗi khi hoàn tiền.';

      if (e.toString().contains('CAPTURE_FULLY_REFUNDED')) {
        errorMessage = 'Giao dịch này đã được hoàn tiền trước đó.';
      }

      setState(() {
        refundMessage = errorMessage;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoàn tiền')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capture ID: ${widget.captureId}'),
            Text('Số tiền: \$${widget.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Text(
              'Trạng thái thanh toán: ${paymentStatus == 'REFUNDED' ? 'Đã hoàn tiền' : 'Đã thanh toán'}',
              style: TextStyle(
                color:
                paymentStatus == 'REFUNDED'
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed:
              paymentStatus == 'REFUNDED' ? null : handleRefund,
              icon: const Icon(Icons.refresh),
              label: const Text('Hoàn tiền'),
            ),
            if (refundMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                refundMessage!,
                style: TextStyle(
                  color:
                  refundMessage == 'Hoàn tiền thành công!'
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
