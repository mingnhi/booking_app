import 'package:flutter/material.dart';
import 'package:frontend/screens/payment/paymentrefund_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ticket_service.dart';
import '../../services/trip_service.dart';
import '../../services/seat_service.dart';
import '../../services/payment_service.dart';
import '../../models/ticket.dart';
import '../../models/trip.dart';
import '../../models/seat.dart';
import '../../models/payment.dart';
import '../home/customer_nav_bar.dart';
import 'package:intl/intl.dart';

class PaidTicketsScreen extends StatefulWidget {
  const PaidTicketsScreen({super.key});

  @override
  _PaidTicketsScreenState createState() => _PaidTicketsScreenState();
}

class _PaidTicketsScreenState extends State<PaidTicketsScreen> {
  @override
  void initState() {
    super.initState();
    _refreshPaidTickets();
  }

  Future<void> _refreshPaidTickets() async {
    final ticketService = Provider.of<TicketService>(context, listen: false);
    final tripService = Provider.of<TripService>(context, listen: false);
    final seatService = Provider.of<SeatService>(context, listen: false);
    final paymentService = Provider.of<PaymentService>(context, listen: false);

    try {
      await Future.wait([
        ticketService.fetchTickets(),
        tripService.fetchTrips(),
        seatService.fetchSeats(),
        paymentService.fetchPayments(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi làm mới dữ liệu: $e')));
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
            textStyle: GoogleFonts.poppins(
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
            'Vé đã thanh toán',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshPaidTickets,
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

            final paidTickets =
                ticketService.tickets
                    .where(
                      (ticket) =>
                          paymentService.getPaymentByTicketId(ticket.id) !=
                          null,
                    )
                    .toList();

            if (paidTickets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_bus,
                      size: 80,
                      color: Color(0xFF2474E5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Không có vé nào đã thanh toán',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Vui lòng kiểm tra lại hoặc liên hệ hỗ trợ.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshPaidTickets,
                      child: Text('Thử lại', style: GoogleFonts.poppins()),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshPaidTickets,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: paidTickets.length,
                itemBuilder: (context, index) {
                  final ticket = paidTickets[index];
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
                  final payment = paymentService.getPaymentByTicketId(
                    ticket.id,
                  );

                  final availableSeats =
                      seatService.seats
                          .where(
                            (s) =>
                                s.tripId == trip.id &&
                                s.statusSeat == 'AVAILABLE',
                          )
                          .length;

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vé #${ticket.id.substring(0, 8)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2474E5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(
                              Icons.directions_bus,
                              color: Color(0xFF2474E5),
                            ),
                            title: Text(
                              '${trip.departure_location} → ${trip.arrival_location}',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            subtitle: Text(
                              'Khoảng cách: ${trip.distance.toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.event_seat,
                              color: Color(0xFF2474E5),
                            ),
                            title: Text(
                              'Ghế: ${seat.seatNumber}',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            subtitle: Text(
                              'Còn ${availableSeats}/${trip.totalSeats} ghế trống',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.access_time,
                              color: Color(0xFF2474E5),
                            ),
                            title: Text(
                              'Thời gian đi: ${DateFormat('dd/MM/yyyy HH:mm').format(trip.departure_time)}',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.confirmation_number,
                              color: Color(0xFF2474E5),
                            ),
                            title: Text(
                              'Trạng thái: ${ticket.ticket_status}',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.attach_money,
                              color: Color(0xFF2474E5),
                            ),
                            title: Text(
                              'Giá: ${trip.price.toStringAsFixed(0)} VNĐ',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF2474E5),
                            ),
                            title: Text(
                              'Đặt lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.booked_at)}',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child:
                                payment != null
                                    ? (payment.paymentStatus == 'REFUNDED'
                                        ? Text(
                                          'Đã hoàn tiền',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : ElevatedButton(
                                          onPressed: () async {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => RefundScreen(
                                                      paymentId: payment.id!,
                                                      captureId:
                                                          payment.captureId ??
                                                          '',
                                                      amount: trip.price,
                                                    ),
                                              ),
                                            ).then((value) async {
                                              if (value == true) {
                                                // Cập nhật trạng thái payment_status thành REFUNDED
                                                await paymentService
                                                    .updatePaymentStatus(
                                                      payment.id!,
                                                      'REFUNDED',
                                                    );
                                                _refreshPaidTickets();
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          child: Text(
                                            'Hoàn tiền',
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ))
                                    : const SizedBox.shrink(),
                          ),
                        ],
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
              Navigator.pushReplacementNamed(context, '/tickets');
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/auth/profile');
            }
          },
        ),
      ),
    );
  }
}
