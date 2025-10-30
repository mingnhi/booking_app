import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/seat_service.dart';
import '../../services/ticket_service.dart';
import '../../services/trip_service.dart';
import '../../models/seat.dart';
import '../../models/trip.dart';

class SeatListScreen extends StatefulWidget {
  final String tripId;
  final String vehicleId;

  const SeatListScreen({super.key, required this.tripId, required this.vehicleId});

  @override
  _SeatListScreenState createState() => _SeatListScreenState();
}

class _SeatListScreenState extends State<SeatListScreen> with TickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF2474E5); // Đồng bộ với TripDetailScreen
  static const Color accentColor = Color(0xFF5B9EE5); // Đồng bộ với TripDetailScreen
  bool _isBooking = false;
  String? _selectedSeatId;
  final Map<String, AnimationController> _seatAnimations = {};

  @override
  void initState() {
    super.initState();
    _fetchSeats();
    _fetchTrip();
  }

  Future<void> _fetchTrip() async {
    final tripService = Provider.of<TripService>(context, listen: false);
    try {
      await tripService.fetchTripById(widget.tripId, allowUnauthenticated: true);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi khi tải thông tin chuyến đi: $e', Colors.redAccent);
      }
    }
  }

  @override
  void dispose() {
    _seatAnimations.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchSeats() async {
    final seatService = Provider.of<SeatService>(context, listen: false);
    try {
      await seatService.fetchAvailableSeatsByTripId(widget.tripId);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi khi tải danh sách ghế: $e', Colors.redAccent);
      }
    }
  }

  Future<void> _bookTicket(String tripId, BuildContext context) async {
    if (_selectedSeatId == null) {
      _showSnackBar('Vui lòng chọn ghế trước khi đặt vé!', Colors.redAccent);
      return;
    }

    setState(() => _isBooking = true);

    final ticketService = Provider.of<TicketService>(context, listen: false);
    final seatService = Provider.of<SeatService>(context, listen: false);

    final ticketData = {"trip_id": tripId, "seat_id": _selectedSeatId};

    try {
      final newTicket = await ticketService.createTicket(ticketData);
      if (newTicket != null) {
        final seat = seatService.seats.firstWhere((s) => s.id == _selectedSeatId);
        await seatService.updateSeat(
          seat.id,
          Seat(
            id: seat.id,
            tripId: seat.tripId,
            seatNumber: seat.seatNumber,
            statusSeat: 'BOOKED',
            createdAt: seat.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
        _showSnackBar('Đặt vé thành công!', Colors.green);
        Navigator.pop(context, _selectedSeatId);
      } else {
        throw Exception('Không thể tạo vé');
      }
    } catch (e) {
      _showSnackBar('Đặt vé thất bại: $e', Colors.redAccent);
      setState(() => _isBooking = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatSeatNumber(int seatNumber) {
    return 'G${seatNumber.toString().padLeft(2, '0')}';
  }

  Widget _buildSeatIcon(Seat seat) {
    final isSelected = _selectedSeatId == seat.id;
    final isAvailable = seat.statusSeat == 'AVAILABLE';
    final isNotForSale = seat.statusSeat == 'NOT_FOR_SALE';

    _seatAnimations.putIfAbsent(
      seat.id,
          () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );

    final animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _seatAnimations[seat.id]!, curve: Curves.easeInOutBack),
    );

    if (isSelected && !_seatAnimations[seat.id]!.isAnimating && !_seatAnimations[seat.id]!.isCompleted) {
      _seatAnimations[seat.id]!.forward();
    } else if (!isSelected && _seatAnimations[seat.id]!.isCompleted) {
      _seatAnimations[seat.id]!.reverse();
    }

    return GestureDetector(
      onTap: isAvailable
          ? () {
        HapticFeedback.lightImpact();
        setState(() => _selectedSeatId = isSelected ? null : seat.id);
      }
          : null,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: isAvailable ? 1.0 : 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [Colors.greenAccent.shade200, Colors.green.shade600]
                        : isAvailable
                        ? [Colors.grey.shade100, Colors.grey.shade300]
                        : [Colors.grey.shade300, Colors.grey.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? Colors.green.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected ? Colors.greenAccent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 36,
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                    if (isNotForSale)
                      Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.black54,
                      ),
                    Positioned(
                      bottom: 4,
                      child: Text(
                        _formatSeatNumber(seat.seatNumber),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
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

  Widget _buildSeatLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Icons.event_seat, Colors.grey, 'Còn trống'),
        const SizedBox(width: 16),
        _buildLegendItem(Icons.close, Colors.grey, 'Không bán'),
        const SizedBox(width: 16),
        _buildLegendItem(Icons.event_seat, Colors.green, 'Đang chọn'),
      ],
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(primary: primaryColor, secondary: accentColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor, // Đồng bộ với TripDetailScreen
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24), // Đồng bộ padding
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Consumer<TripService>(
            builder: (context, tripService, _) {
              final trip = tripService.trips.firstWhere(
                    (t) => t.id == widget.tripId,
                orElse: () => Trip(
                  id: '',
                  vehicle_id: '',
                  departure_location: '',
                  arrival_location: '',
                  departure_time: DateTime.now(),
                  arrival_time: DateTime.now(),
                  price: 0,
                  distance: 0,
                  totalSeats: 0,
                ),
              );

              // Map English day names to Vietnamese abbreviations
              final vietnameseDays = {
                'Monday': 'T2',
                'Tuesday': 'T3',
                'Wednesday': 'T4',
                'Thursday': 'T5',
                'Friday': 'T6',
                'Saturday': 'T7',
                'Sunday': 'CN',
              };

              // Format the departure time
              final dayOfWeek = DateFormat('EEEE').format(trip.departure_time);
              final vietnameseDay = vietnameseDays[dayOfWeek] ?? 'T?';
              final formattedTime = '${DateFormat('HH:mm').format(trip.departure_time)} - $vietnameseDay, ${DateFormat('dd/MM/yyyy').format(trip.departure_time)}';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vehicleId.isNotEmpty ? widget.vehicleId : 'Chọn Ghế',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  Text(
                    trip.id.isNotEmpty ? formattedTime : '',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),
                  ),
                ],
              );
            },
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/trip/detail/id',
                  arguments: widget.tripId,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Chi tiết xe',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Consumer<SeatService>(
            builder: (context, seatService, _) {
              if (seatService.isLoading || _isBooking) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }

              final availableSeats = seatService.seats;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      if (availableSeats.isEmpty)
                        Text(
                          'Không có ghế khả dụng.',
                          style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 14),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.directions_bus, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(height: 40),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: availableSeats.length,
                          itemBuilder: (context, index) => _buildSeatIcon(availableSeats[index]),
                        ),
                        const SizedBox(height: 40),
                        _buildSeatLegend(),
                        const SizedBox(height: 10),
                        AnimatedOpacity(
                          opacity: _isBooking ? 0.7 : 1.0, // Đồng bộ opacity với TripDetailScreen
                          duration: const Duration(milliseconds: 300), // Đồng bộ duration
                          child: ElevatedButton(
                            onPressed: _isBooking ? null : () => _bookTicket(widget.tripId, context),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              elevation: 3, // Đồng bộ elevation
                            ),
                            child: _isBooking
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'Đặt Vé Ngay',
                              style: GoogleFonts.montserrat(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}