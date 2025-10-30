import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/ticket_service.dart';
import '../../services/trip_service.dart';
import '../../services/seat_service.dart';
import '../../services/auth_service.dart';
import '../../models/ticket.dart';
import '../../models/trip.dart';
import '../../models/seat.dart';
import '../payment/payment_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  Ticket? _ticket;
  String? _errorMessage;
  String? _selectedTripId;
  String? _selectedSeatId;
  List<Seat> _availableSeats = [];
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController = TextEditingController(text: 'Không xác định');
  late TextEditingController _emailController = TextEditingController(text: 'Không xác định');
  late TextEditingController _phoneController = TextEditingController(text: 'Không xác định');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.getProfile().then((_) {
        if (authService.currentUser != null && mounted) {
          setState(() {
            _fullNameController.text = authService.currentUser!.fullName ?? 'Không xác định';
            _emailController.text = authService.currentUser!.email ?? 'Không xác định';
            _phoneController.text = authService.currentUser!.phoneNumber ?? 'Không xác định';
          });
        }
      });
    });

    _fetchTicketDetails();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchTicketDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ticketService = Provider.of<TicketService>(context, listen: false);
    final tripService = Provider.of<TripService>(context, listen: false);
    final seatService = Provider.of<SeatService>(context, listen: false);

    try {
      await Future.wait([
        ticketService.fetchTicketById(widget.ticketId),
        tripService.fetchTrips(),
        seatService.fetchSeatsByTripId(''),
      ]);
      final ticket = ticketService.tickets.firstWhere(
            (t) => t.id == widget.ticketId,
        orElse: () => throw Exception('Ticket not found'),
      );
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải chi tiết vé: $e')),
      );
    }
  }

  void _startEditing() {
    if (_ticket!.ticket_status == 'COMPLETED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chỉnh sửa vé đã hoàn thành')),
      );
      return;
    }

    final seatService = Provider.of<SeatService>(context, listen: false);

    setState(() {
      _isEditing = true;
      _selectedTripId = _ticket!.trip_id;
      _selectedSeatId = _ticket!.seat_id;
      _availableSeats = [];
    });

    seatService.fetchSeatsByTripId(_selectedTripId!).then((_) {
      final currentSeat = seatService.seats.firstWhere(
            (seat) => seat.id == _selectedSeatId,
        orElse: () => Seat(
          id: _selectedSeatId ?? '',
          tripId: _selectedTripId ?? '',
          seatNumber: _ticket!.seatNumber ?? 0,
          statusSeat: 'BOOKED',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      seatService.fetchAvailableSeatsByTripId(_selectedTripId!).then((_) {
        setState(() {
          _availableSeats = seatService.seats;
          if (!_availableSeats.contains(currentSeat) && currentSeat.id.isNotEmpty) {
            _availableSeats.add(currentSeat);
          }
        });
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải ghế trống: $e')),
        );
        setState(() {
          _availableSeats = [];
        });
      });
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải tất cả ghế: $e')),
      );
      setState(() {
        _availableSeats = [];
      });
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _selectedTripId = null;
      _selectedSeatId = null;
      _availableSeats = [];
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final ticketService = Provider.of<TicketService>(context, listen: false);
      final seatService = Provider.of<SeatService>(context, listen: false);

      if (_selectedSeatId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thông tin ghế không hợp lệ')),
        );
        return;
      }

      final ticketData = {
        'trip_id': _selectedTripId,
        'seat_id': _selectedSeatId,
      };

      try {
        final updatedTicket = await ticketService.updateTicket(_ticket!.id, ticketData);
        if (updatedTicket != null) {
          if (_ticket!.seat_id != _selectedSeatId) {
            final oldSeat = seatService.seats.firstWhere(
                  (s) => s.id == _ticket!.seat_id,
              orElse: () => Seat(
                id: _ticket!.seat_id,
                tripId: _ticket!.trip_id,
                seatNumber: _ticket!.seatNumber ?? 0,
                statusSeat: 'BOOKED',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            if (oldSeat.id.isNotEmpty) {
              await seatService.updateSeat(
                oldSeat.id,
                Seat(
                  id: oldSeat.id,
                  tripId: oldSeat.tripId,
                  seatNumber: oldSeat.seatNumber,
                  statusSeat: 'AVAILABLE',
                  createdAt: oldSeat.createdAt,
                  updatedAt: DateTime.now(),
                ),
              );
            }

            final newSeat = seatService.seats.firstWhere(
                  (s) => s.id == _selectedSeatId,
              orElse: () => Seat(
                id: _selectedSeatId!,
                tripId: _selectedTripId!,
                seatNumber: _availableSeats.firstWhere(
                      (s) => s.id == _selectedSeatId,
                  orElse: () => Seat(
                    id: _selectedSeatId!,
                    tripId: _selectedTripId!,
                    seatNumber: 0,
                    statusSeat: 'AVAILABLE',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ).seatNumber,
                statusSeat: 'AVAILABLE',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            if (newSeat.id.isNotEmpty) {
              await seatService.updateSeat(
                newSeat.id,
                Seat(
                  id: newSeat.id,
                  tripId: newSeat.tripId,
                  seatNumber: newSeat.seatNumber,
                  statusSeat: 'BOOKED',
                  createdAt: newSeat.createdAt,
                  updatedAt: DateTime.now(),
                ),
              );
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật vé thành công', style: GoogleFonts.montserrat()),
              backgroundColor: const Color(0xFF2474E5),
            ),
          );
          setState(() {
            _isEditing = false;
            _selectedTripId = null;
            _selectedSeatId = null;
            _availableSeats = [];
            _ticket = updatedTicket;
          });
          await _fetchTicketDetails();
        } else {
          throw Exception('Không thể cập nhật vé');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật vé thất bại: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: const Color(0xFF2474E5),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2474E5),
          secondary: Color(0xFF5B9EE5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2474E5),
          title: Text(
            'Thông tin chi tiết vé',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchTicketDetails,
            ),
          ],
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2474E5)))
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Color(0xFF2474E5)),
                  const SizedBox(height: 20),
                  Text(
                    'Lỗi: $_errorMessage',
                    style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchTicketDetails,
                    child: Text('Thử lại', style: GoogleFonts.montserrat()),
                  ),
                ],
              ),
            )
                : _ticket == null
                ? Center(
              child: Text(
                'Không tìm thấy vé',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
                : Consumer3<TripService, SeatService, AuthService>(
              builder: (context, tripService, seatService, authService, child) {
                final trip = tripService.trips.firstWhere(
                      (t) => t.id == _ticket!.trip_id,
                  orElse: () => Trip(
                    id: '',
                    vehicle_id: '',
                    departure_location: 'Không xác định',
                    arrival_location: 'Không xác định',
                    departure_time: DateTime.now(),
                    arrival_time: DateTime.now(),
                    price: 0.0,
                    distance: 0.0,
                    totalSeats: 0,
                  ),
                );
                final seat = seatService.seats.firstWhere(
                      (s) => s.id == _ticket!.seat_id,
                  orElse: () => Seat(
                    id: _ticket!.seat_id,
                    tripId: _ticket!.trip_id,
                    seatNumber: _ticket!.seatNumber ?? 0,
                    statusSeat: 'BOOKED',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  children: [
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Thông tin hành khách'),
                            _buildDetailRow(
                              title: 'Họ và tên',
                              subtitle: _fullNameController.text,
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildDetailRow(
                              title: 'Số điện thoại',
                              subtitle: _phoneController.text,
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildDetailRow(
                              title: 'Địa chỉ email',
                              subtitle: _emailController.text,
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              'Thông tin lượt đi',
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 19,
                                fontWeight: FontWeight.bold, // Keep the bold weight
                                color: const Color(0xFF2474E5), // Same color as 'Tuyến xe'
                              ),
                            ),
                            _buildDetailRow(
                              title: 'Tuyến xe',
                              subtitle: '${trip.departure_location} - ${trip.arrival_location}',
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: const Color(0xFF2474E5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildDetailRow(
                              title: 'Thời gian khởi hành',
                              subtitle: DateFormat('HH:mm dd/MM/yyyy').format(trip.departure_time),
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: const Color(0xFF2474E5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildDetailRow(
                              title: 'Số lượng ghế',
                              subtitle: '1',
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: const Color(0xFF2474E5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildDetailRow(
                              title: 'Số ghế',
                              subtitle: 'Ghế ${seat.seatNumber}',
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: const Color(0xFF2474E5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildDetailRow(
                              title: 'Loại xe',
                              subtitle: '${trip.vehicle_id} - ${trip.totalSeats} chỗ',
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: const Color(0xFF2474E5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildDetailRow(
                              title: 'Trạng thái',
                              subtitle: '${_ticket!.ticket_status}',
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: const Color(0xFF2474E5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildDetailRow(
                              title: 'Thời gian lên xe',
                              subtitle: DateFormat('HH:mm dd/MM/yyyy').format(_ticket!.booked_at),
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: const Color(0xFF2474E5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Tổng tiền lượt đi'),
                            _buildDetailRow(
                              title: '',
                              subtitle: '${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(trip.price)}đ',
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _startEditing,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5B9EE5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24)),
                                  textStyle: GoogleFonts.montserrat(
                                      fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                child: Text('Chỉnh sửa'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentScreen(
                                        amount: trip.price,
                                        ticketId: _ticket!.id,
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      _fetchTicketDetails();
                                    }
                                  });
                                },
                                child: Text('Thanh toán'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_isEditing)
              ModalBarrier(color: Colors.black54, dismissible: false),
            if (_isEditing)
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Chỉnh sửa vé',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2474E5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Consumer<TripService>(
                            builder: (context, tripService, child) {
                              final trip = tripService.trips.firstWhere(
                                    (t) => t.id == _selectedTripId,
                                orElse: () => Trip(
                                  id: '',
                                  vehicle_id: '',
                                  departure_location: 'Không xác định',
                                  arrival_location: 'Không xác định',
                                  departure_time: DateTime.now(),
                                  arrival_time: DateTime.now(),
                                  price: 0.0,
                                  distance: 0.0,
                                  totalSeats: 0,
                                ),
                              );
                              return TextFormField(
                                initialValue:
                                '${trip.departure_location} → ${trip.arrival_location}',
                                decoration: InputDecoration(
                                  labelText: 'Chuyến đi',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                style: GoogleFonts.montserrat(),
                                enabled: false,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedSeatId,
                            decoration: InputDecoration(
                              labelText: 'Ghế',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _availableSeats
                                .where((seat) => seat.seatNumber != 0)
                                .map((seat) {
                              return DropdownMenuItem<String>(
                                value: seat.id,
                                child: Text('Ghế ${seat.seatNumber}',
                                    style: GoogleFonts.montserrat()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSeatId = value;
                              });
                            },
                            validator: (value) =>
                            value == null ? 'Vui lòng chọn ghế' : null,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _cancelEditing,
                                child: Text('Hủy',
                                    style: GoogleFonts.montserrat(color: Colors.red)),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _saveChanges,
                                child: Text('Lưu', style: GoogleFonts.montserrat()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: textStyle ??
            GoogleFonts.montserrat(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String subtitle,
    TextStyle? textStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          Flexible(
            child: Text(
              subtitle,
              style: textStyle ??
                  GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.black,
                  ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}