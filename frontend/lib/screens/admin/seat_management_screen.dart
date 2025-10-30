import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SeatManagementScreen extends StatefulWidget {
  const SeatManagementScreen({super.key});

  @override
  _SeatManagementScreenState createState() => _SeatManagementScreenState();
}

class _SeatManagementScreenState extends State<SeatManagementScreen> {
  List<dynamic> seats = [];
  List<dynamic> trips = [];
  bool isLoading = true;
  bool isLoadingTrips = false;
  String? selectedStatus;
  final _formKey = GlobalKey<FormState>();
  String? _selectedTripId;
  final _seatNumberController = TextEditingController();
  String _statusSeat = 'AVAILABLE';
  final List<String> _seatStatusOptions = [
    'AVAILABLE',
    'BOOKED',
    'UNAVAILABLE',
  ];

  @override
  void initState() {
    super.initState();
    _loadSeats();
    _loadTrips();
  }

  @override
  void dispose() {
    _seatNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSeats() async {
    setState(() {
      isLoading = true;
    });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      final fetchedSeats = await adminService.getSeats();
      setState(() {
        seats = fetchedSeats;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải danh sách ghế: $e')));
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadTrips() async {
    setState(() {
      isLoadingTrips = true;
    });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      final fetchedTrips = await adminService.getTrips();
      setState(() {
        trips = fetchedTrips;
        isLoadingTrips = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách chuyến đi: $e')),
      );
      setState(() {
        isLoadingTrips = false;
      });
    }
  }

  void _showAddSeatDialog() {
    _seatNumberController.clear();
    _selectedTripId = null;
    _statusSeat = 'AVAILABLE';
    _showSeatDialog(null);
  }

  void _showEditSeatDialog(dynamic seat) {
    _seatNumberController.text = seat['seat_number'].toString();
    _selectedTripId = seat['trip_id'];
    _statusSeat = seat['status_seat'] ?? 'AVAILABLE';
    _showSeatDialog(seat);
  }

  void _showSeatDialog(dynamic seat) {
    final isEditing = seat != null;
    final title = isEditing ? 'Chỉnh sửa ghế' : 'Thêm ghế mới';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  content: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Chuyến đi',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedTripId,
                            items:
                                trips.map<DropdownMenuItem<String>>((trip) {
                                  // Hiển thị thông tin chuyến đi (điểm đi - điểm đến)
                                  String tripInfo =
                                      '${trip['departure_location'] ?? 'Unknown'} - ${trip['arrival_location'] ?? 'Unknown'}';
                                  return DropdownMenuItem<String>(
                                    value: trip['_id'],
                                    child: Text(tripInfo),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTripId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng chọn chuyến đi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _seatNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Số ghế',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập số ghế';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Số ghế phải là số';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Trạng thái ghế',
                              border: OutlineInputBorder(),
                            ),
                            value: _statusSeat,
                            items:
                                _seatStatusOptions
                                    .map<DropdownMenuItem<String>>((status) {
                                      return DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      );
                                    })
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _statusSeat = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed:
                          () => _saveSeat(isEditing ? seat['_id'] : null),
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _saveSeat(String? seatId) async {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      setState(() {
        isLoading = true;
      });

      final adminService = Provider.of<AdminService>(context, listen: false);
      final seatData = {
        'trip_id': _selectedTripId,
        'seat_number': int.parse(_seatNumberController.text),
        'status_seat': _statusSeat,
      };

      try {
        if (seatId != null) {
          // Cập nhật ghế
          await adminService.updateSeat(seatId, seatData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ghế thành công')),
          );
        } else {
          // Thêm ghế mới
          await adminService.createSeat(seatData);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Thêm ghế thành công')));
        }
        _loadSeats();
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _confirmDeleteSeat(String seatId, int seatNumber) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Xác nhận xóa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text('Bạn có chắc chắn muốn xóa ghế số $seatNumber?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    if (result == true) {
      setState(() {
        isLoading = true;
      });

      try {
        final adminService = Provider.of<AdminService>(context, listen: false);
        await adminService.deleteSeat(seatId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa ghế thành công')));
        _loadSeats();
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa ghế: $e')));
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_seat, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Chưa có ghế nào',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để thêm ghế mới',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  List<dynamic> get filteredSeats {
    if (selectedStatus == null) return seats;
    return seats
        .where((seat) => seat['status_seat'] == selectedStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý ghế',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSeats,
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
                    child: Row(
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
                          hint: Text('Tất cả', style: GoogleFonts.poppins()),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'Tất cả',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: 'AVAILABLE',
                              child: Text(
                                'Có sẵn',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: 'BOOKED',
                              child: Text(
                                'Đã đặt',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: 'UNAVAILABLE',
                              child: Text(
                                'Không khả dụng',
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
                  ),
                  Expanded(
                    child:
                        filteredSeats.isEmpty
                            ? _buildEmptyState()
                            : _buildSeatList(),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSeatDialog,
        tooltip: 'Thêm ghế mới',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSeatList() {
    return RefreshIndicator(
      onRefresh: _loadSeats,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: filteredSeats.length,
        itemBuilder: (context, index) {
          final seat = filteredSeats[index];
          return Card(
            elevation: 2,
            child: InkWell(
              onTap: () => _showEditSeatDialog(seat),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ghế ${seat['seat_number']}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(seat['status_seat']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            seat['status_seat'] ?? 'UNAVAILABLE',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      'Chuyến: ${_getTripInfo(seat['trip_id'])}',
                      style: GoogleFonts.poppins(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (seat['createdAt'] != null)
                      Text(
                        'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(seat['createdAt']))}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditSeatDialog(seat),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed:
                              () => _confirmDeleteSeat(
                                seat['_id'],
                                seat['seat_number'],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'BOOKED':
        return Colors.red;
      case 'UNAVAILABLE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTripInfo(String tripId) {
    final trip = trips.firstWhere(
      (trip) => trip['_id'] == tripId,
      orElse:
          () => {
            'departure_location': 'Unknown',
            'arrival_location': 'Unknown',
          },
    );
    return '${trip['departure_location'] ?? 'Unknown'} - ${trip['arrival_location'] ?? 'Unknown'}';
  }
}
