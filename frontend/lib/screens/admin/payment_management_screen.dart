import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/payment.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({Key? key}) : super(key: key);

  @override
  _PaymentManagementScreenState createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  List<Payment> payments = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedStatus;
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      isLoading = true;
    });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      final fetchedPayments = await adminService.getPayments();
      setState(() {
        payments = fetchedPayments.map((p) => Payment.fromJson(p)).toList();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách thanh toán: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Payment> get filteredPayments {
    return payments.where((payment) {
      // Lọc theo trạng thái
      if (selectedStatus != null && payment.paymentStatus != selectedStatus) {
        return false;
      }

      // Lọc theo ngày
      if (startDate != null || endDate != null) {
        if (payment.paymentDate == null) return false;
        if (startDate != null && payment.paymentDate!.isBefore(startDate!)) {
          return false;
        }
        if (endDate != null &&
            payment.paymentDate!.isAfter(
              endDate!.add(const Duration(days: 1)),
            )) {
          return false;
        }
      }

      // Tìm kiếm theo ID
      if (searchQuery.isNotEmpty) {
        final paymentId = payment.id?.toLowerCase() ?? '';
        final ticketId = payment.ticketId.toLowerCase();
        final orderId = payment.orderId?.toLowerCase() ?? '';
        final paypalPaymentId = payment.paypalPaymentId?.toLowerCase() ?? '';

        if (!paymentId.contains(searchQuery.toLowerCase()) &&
            !ticketId.contains(searchQuery.toLowerCase()) &&
            !orderId.contains(searchQuery.toLowerCase()) &&
            !paypalPaymentId.contains(searchQuery.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025, 12, 31),
      initialDateRange:
          startDate != null && endDate != null
              ? DateTimeRange(start: startDate!, end: endDate!)
              : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      case 'REFUNDED':
        return Colors.purple;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Thành công';
      case 'FAILED':
        return 'Thất bại';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return 'Không xác định';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Chưa có giao dịch nào',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList() {
    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPayments.length,
        itemBuilder: (context, index) {
          final payment = filteredPayments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Giao dịch #${payment.id?.substring(0, 8).toUpperCase() ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(payment.paymentStatus),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(payment.paymentStatus),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Vé: ${payment.ticketId}', style: GoogleFonts.poppins()),
                  const SizedBox(height: 4),
                  Text(
                    'Số tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(payment.amount)}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phương thức: ${payment.paymentMethod}',
                    style: GoogleFonts.poppins(),
                  ),
                  if (payment.orderId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Mã đơn hàng: ${payment.orderId}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  if (payment.paypalPaymentId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'PayPal ID: ${payment.paypalPaymentId}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  if (payment.paymentDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Ngày thanh toán: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý thanh toán',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Hàng filter đầu tiên
                        Row(
                          children: [
                            Text(
                              'Lọc theo trạng thái:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: selectedStatus,
                              hint: Text(
                                'Tất cả',
                                style: GoogleFonts.poppins(),
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'Tất cả',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'SUCCESS',
                                  child: Text(
                                    'Thành công',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'PENDING',
                                  child: Text(
                                    'Đang xử lý',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'FAILED',
                                  child: Text(
                                    'Thất bại',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'REFUNDED',
                                  child: Text(
                                    'Đã hoàn tiền',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'CANCELLED',
                                  child: Text(
                                    'Đã hủy',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedStatus = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Hàng filter thứ hai
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Tìm kiếm theo ID giao dịch, ID vé, Order ID hoặc PayPal ID',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon:
                                      searchQuery.isNotEmpty
                                          ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                                searchQuery = '';
                                              });
                                            },
                                          )
                                          : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _selectDateRange(context),
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                'Chọn ngày',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ],
                        ),
                        if (startDate != null || endDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  'Khoảng thời gian: ',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${DateFormat('dd/MM/yyyy').format(startDate ?? DateTime.now())} - ${DateFormat('dd/MM/yyyy').format(endDate ?? DateTime.now())}',
                                  style: GoogleFonts.poppins(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      startDate = null;
                                      endDate = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        filteredPayments.isEmpty
                            ? _buildEmptyState()
                            : _buildPaymentList(),
                  ),
                ],
              ),
    );
  }
}
