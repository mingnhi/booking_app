import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/ticket_service.dart';
import '../../services/trip_service.dart';
import '../../services/seat_service.dart';
import '../../services/payment_service.dart';
import '../../models/ticket.dart';
import '../../models/trip.dart';
import '../../models/seat.dart';
import '../home/customer_nav_bar.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  bool _hasAttemptedRefresh = false;

  @override
  void initState() {
    super.initState();
    _refreshTickets();
  }

  Future<void> _refreshTickets() async {
    final ticketService = Provider.of<TicketService>(context, listen: false);
    final tripService = Provider.of<TripService>(context, listen: false);
    final seatService = Provider.of<SeatService>(context, listen: false);
    final paymentService = Provider.of<PaymentService>(context, listen: false);

    try {
      await tripService.fetchTrips();
      final tripId =
          tripService.trips.isNotEmpty ? tripService.trips.first.id : null;
      if (tripId != null) {
        await Future.wait([
          ticketService.fetchTickets(),
          seatService.fetchAvailableSeatsByTripId(tripId),
          paymentService.fetchPayments(),
        ]);
      } else {
        await Future.wait([
          ticketService.fetchTickets(),
          paymentService.fetchPayments(),
        ]);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')));
    }
  }

  Future<void> _deleteTicket(
    String ticketId,
    String seatId,
    String tripId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Xác nhận xóa', style: GoogleFonts.montserrat()),
            content: Text(
              'Bạn có chắc chắn muốn xóa vé này?',
              style: GoogleFonts.montserrat(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Hủy', style: GoogleFonts.montserrat()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Xóa',
                  style: GoogleFonts.montserrat(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final ticketService = Provider.of<TicketService>(context, listen: false);
      final seatService = Provider.of<SeatService>(context, listen: false);

      try {
        final success = await ticketService.deleteTicket(ticketId);
        if (success) {
          final seat = seatService.seats.firstWhere(
            (s) => s.id == seatId,
            orElse:
                () => Seat(
                  id: seatId,
                  tripId: tripId,
                  seatNumber: 0,
                  statusSeat: 'BOOKED',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
          );
          if (seat.statusSeat == 'BOOKED') {
            final updatedSeat = await seatService.updateSeat(
              seat.id,
              Seat(
                id: seat.id,
                tripId: seat.tripId,
                seatNumber: seat.seatNumber,
                statusSeat: 'AVAILABLE',
                createdAt: seat.createdAt,
                updatedAt: DateTime.now(),
              ),
            );
            if (updatedSeat == null) {
              throw Exception('Không thể cập nhật trạng thái ghế');
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Xóa vé thành công',
                style: GoogleFonts.montserrat(),
              ),
              backgroundColor: const Color(0xFF2474E5),
            ),
          );
          await _refreshTickets();
        } else {
          throw Exception('Không thể xóa vé');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xóa vé thất bại: $e')));
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
            backgroundColor: const Color(0xFF2474E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2474E5),
          title: Text(
            'Vé của tôi',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/paid_tickets');
              },
              child: Text(
                'Đã thanh toán',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshTickets,
            ),
          ],
        ),
        body: Consumer4<
          TicketService,
          TripService,
          SeatService,
          PaymentService
        >(
          builder: (
            context,
            ticketService,
            tripService,
            seatService,
            paymentService,
            child,
          ) {
            if (ticketService.isLoading ||
                tripService.isLoading ||
                seatService.isLoading ||
                paymentService.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2474E5)),
              );
            }

            final unpaidTickets =
                ticketService.tickets
                    .where(
                      (ticket) =>
                          paymentService.getPaymentByTicketId(ticket.id) ==
                          null,
                    )
                    .toList();

            // Nếu danh sách vé trống và chưa thử làm mới, gọi _refreshTickets sau khi build hoàn tất
            if (unpaidTickets.isEmpty && !_hasAttemptedRefresh) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                setState(() {
                  _hasAttemptedRefresh = true;
                });
                await _refreshTickets();
              });
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2474E5)),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshTickets,
              child:
                  unpaidTickets.isEmpty
                      ? Center(
                        child: Text(
                          'Không có vé chưa thanh toán',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2474E5),
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: unpaidTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = unpaidTickets[index];
                          final trip = tripService.trips.firstWhere(
                            (t) => t.id == ticket.trip_id,
                            orElse:
                                () => Trip(
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
                            (s) => s.id == ticket.seat_id,
                            orElse:
                                () => Seat(
                                  id: ticket.seat_id,
                                  tripId: ticket.trip_id,
                                  seatNumber: ticket.seatNumber ?? 0,
                                  statusSeat: 'BOOKED',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                          );

                          // Tính thời gian hành trình
                          final duration = trip.arrival_time.difference(
                            trip.departure_time,
                          );
                          final hours = duration.inHours;
                          final minutes = duration.inMinutes % 60;
                          final durationText =
                              '$hours giờ ${minutes > 0 ? '$minutes phút' : ''}';

                          // Tính số ghế trống
                          final bookedSeats =
                              seatService.seats
                                  .where(
                                    (seat) =>
                                        seat.tripId == trip.id &&
                                        seat.statusSeat == 'BOOKED',
                                  )
                                  .length;
                          final availableSeatsCount =
                              trip.totalSeats - bookedSeats;

                          return Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/ticket/detail',
                                  arguments: ticket.id,
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Khung 1: ID vé và trạng thái
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Vé #${ticket.id.substring(0, 8)}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2474E5),
                                          ),
                                        ),
                                        Text(
                                          ticket.ticket_status,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      color: Color(0xFFCCCCCC),
                                      thickness: 1,
                                      height: 20,
                                    ),
                                    // Khung 2: Hình ảnh và thông tin xe
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.2,
                                                ),
                                                spreadRadius: 2,
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.asset(
                                              'assets/images/xe-giuong-nam-co-bao-nhieu-cho-so-ghe-xe-giuong-nam-danh-so-nhu-the-nao-vju447.png',
                                              width: 100,
                                              height: 65,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(
                                              '${trip.vehicle_id} - ${trip.totalSeats} chỗ',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Khung 3: Thời gian, địa điểm, giá tiền, chỗ trống
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  DateFormat(
                                                    'HH:mm',
                                                  ).format(trip.departure_time),
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  durationText,
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  DateFormat(
                                                    'HH:mm',
                                                  ).format(trip.arrival_time),
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Container(
                                                          width: 20,
                                                          height: 13,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                                color:
                                                                    const Color(
                                                                      0xFF2474E5,
                                                                    ),
                                                              ),
                                                        ),
                                                        Container(
                                                          width: 4,
                                                          height: 4,
                                                          decoration:
                                                              const BoxDecoration(
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      trip.departure_location,
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 25,
                                                  child: VerticalDivider(
                                                    color: Colors.grey,
                                                    thickness: 1,
                                                    width: 20,
                                                  ),
                                                ),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      color: Colors.redAccent,
                                                      size: 19,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      trip.arrival_location,
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(trip.price)}đ',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'Ghế: ${seat.seatNumber}',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
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
          },
        ),
        bottomNavigationBar: CustomNavBar(
          currentIndex: 2,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/trip/search');
            } else if (index == 2) {
              // Đã ở màn hình này
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/auth/profile');
            }
          },
        ),
      ),
    );
  }
}
