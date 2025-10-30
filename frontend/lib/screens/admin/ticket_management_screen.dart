import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TicketManagementScreen extends StatefulWidget {
  const TicketManagementScreen({Key? key}) : super(key: key);

  @override
  _TicketManagementScreenState createState() => _TicketManagementScreenState();
}

class _TicketManagementScreenState extends State<TicketManagementScreen> {
  List<dynamic> tickets = [];
  bool isLoading = true;
  String? selectedStatus;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedTripId;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final adminService = Provider.of<AdminService>(context, listen: false);
    final fetchedTickets = await adminService.getTickets();
    setState(() {
      tickets = fetchedTickets;
      isLoading = false;
    });
  }

  List<dynamic> get filteredTickets {
    return tickets.where((ticket) {
      // Lọc theo trạng thái
      if (selectedStatus != null && ticket['ticket_status'] != selectedStatus) {
        return false;
      }

      // Lọc theo ngày
      if (startDate != null || endDate != null) {
        final ticketDate = DateTime.parse(ticket['booked_at']);
        if (startDate != null && ticketDate.isBefore(startDate!)) {
          return false;
        }
        if (endDate != null &&
            ticketDate.isAfter(endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Lọc theo chuyến đi
      if (selectedTripId != null &&
          ticket['trip_id'].toString() != selectedTripId) {
        return false;
      }

      // Tìm kiếm theo ID
      if (searchQuery.isNotEmpty) {
        final ticketId = ticket['_id'].toString().toLowerCase();
        if (!ticketId.contains(searchQuery.toLowerCase())) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                  value: 'BOOKED',
                                  child: Text(
                                    'Đã xác nhận',
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
                                DropdownMenuItem<String>(
                                  value: 'COMPLETED',
                                  child: Text(
                                    'Hoàn tất',
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
                                  hintText: 'Tìm kiếm theo ID vé',
                                  prefixIcon: const Icon(Icons.search),
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
                        filteredTickets.isEmpty
                            ? _buildEmptyState()
                            : _buildTicketList(),
                  ),
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có vé nào',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vé sẽ được tạo khi người dùng đặt chỗ',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView.builder(
        itemCount: filteredTickets.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final ticket = filteredTickets[index];
          final purchaseDate = DateTime.parse(ticket['booked_at']);
          final formatter = DateFormat('dd/MM/yyyy HH:mm');

          return Card(
            elevation: 2,
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
                          'Vé #${ticket['_id'].substring(0, 8).toUpperCase()}',
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
                          color: _getStatusColor(ticket['ticket_status']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(ticket['ticket_status']),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _showTicketDetails(context, ticket);
                        },
                        icon: const Icon(Icons.visibility),
                        label: Text('Chi tiết', style: GoogleFonts.poppins()),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showUpdateStatusDialog(context, ticket);
                        },
                        icon: const Icon(Icons.edit),
                        label: Text('Cập nhật', style: GoogleFonts.poppins()),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          _showDeleteConfirmation(context, ticket['_id']);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        label: Text('Xóa', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "BOOKED":
        return Colors.green;
      case "CANCELLED":
        return Colors.orange;
      case "COMPLETED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "BOOKED":
        return 'Đã xác nhận';
      case "CANCELLED":
        return 'Đã hủy';
      case 'COMPLETED':
        return 'Hoàn tất';
      default:
        return 'Không xác định';
    }
  }

  void _showTicketDetails(BuildContext context, dynamic ticket) {
    final purchaseDate = DateTime.parse(ticket['booked_at']);
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Chi tiết vé',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('ID', ticket['_id'].toString()),
                  _buildDetailRow(
                    'Trạng thái',
                    _getStatusText(ticket['ticket_status'].toString()),
                  ),
                  _buildDetailRow(
                    'Người dùng',
                    ticket['user'] != null
                        ? (ticket['user']['full_name']?.toString() ??
                            ticket['user_id'].toString())
                        : ticket['user_id'].toString(),
                  ),
                  _buildDetailRow(
                    'Chuyến đi',
                    ticket['trip_id'] is Map
                        ? "${ticket['trip_id']['departure_location'].toString()} → ${ticket['trip_id']['arrival_location'].toString()}"
                        : ticket['trip_id'].toString(),
                  ),

                  _buildDetailRow(
                    'Ghế',
                    ticket['seat'] is Map
                        ? ticket['seat']['seat_number'].toString()
                        : ticket['seat_id'].toString(),
                  ),
                  _buildDetailRow('Ngày mua', formatter.format(purchaseDate)),
                  _buildDetailRow(
                    'Giá',
                    ticket['trip_id']['price'] != null
                        ? NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: 'đ',
                        ).format(ticket['trip_id']['price'])
                        : 'Không có dữ liệu',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Đóng', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, dynamic ticket) {
    String selectedStatus = ticket['ticket_status'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Cập nhật trạng thái vé',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text('Đã xác nhận', style: GoogleFonts.poppins()),
                  value: 'COMPLETED',
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    selectedStatus = value!;
                    Navigator.pop(context);
                    _showUpdateStatusDialog(context, {
                      ...ticket,
                      'ticket_status': selectedStatus,
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text('Đã Booked', style: GoogleFonts.poppins()),
                  value: 'BOOKED',
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    selectedStatus = value!;
                    Navigator.pop(context);
                    _showUpdateStatusDialog(context, {
                      ...ticket,
                      'ticket_status': selectedStatus,
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text('Đã hủy', style: GoogleFonts.poppins()),
                  value: 'CANCELLED',
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    selectedStatus = value!;
                    Navigator.pop(context);
                    _showUpdateStatusDialog(context, {
                      ...ticket,
                      'ticket_status': selectedStatus,
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateTicketStatus(ticket['_id'], selectedStatus);
                  Navigator.pop(context);
                },
                child: Text('Cập nhật', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  Future<void> _updateTicketStatus(String ticketId, String status) async {
    final adminService = Provider.of<AdminService>(context, listen: false);

    try {
      await adminService.updateTicketStatus(ticketId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật trạng thái vé thành công')),
      );
      _loadTickets(); // Reload tickets after update
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  void _showDeleteConfirmation(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Xác nhận xóa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Bạn có chắc chắn muốn xóa vé này không? Hành động này không thể hoàn tác.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  _deleteTicket(ticketId);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Xóa', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteTicket(String ticketId) async {
    final adminService = Provider.of<AdminService>(context, listen: false);

    try {
      await adminService.deleteTicket(ticketId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xóa vé thành công')));
      _loadTickets(); // Reload tickets after deletion
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }
}
