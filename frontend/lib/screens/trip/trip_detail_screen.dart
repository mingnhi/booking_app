  import 'package:flutter/material.dart';
  import 'package:frontend/screens/seat/seat_list_screen.dart';
  import 'package:provider/provider.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:intl/intl.dart';
  import '../../services/trip_service.dart';
  import '../../services/location_service.dart';
  import '../../services/auth_service.dart';
  import '../../models/trip.dart';
  import '../../models/location.dart';

  class TripDetailScreen extends StatefulWidget {
    final String tripId;

    const TripDetailScreen({super.key, required this.tripId});

    static const routeName = '/trip/detail/id';

    @override
    _TripDetailScreenState createState() => _TripDetailScreenState();
  }

  class _TripDetailScreenState extends State<TripDetailScreen> {
    static const Color primaryColor = Color(0xFF2474E5);
    bool _isBooking = false;
    String? _tripId;

    @override
    void initState() {
      super.initState();
      _tripId = widget.tripId;
      Future.microtask(() async {
        final tripService = Provider.of<TripService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        try {
          await tripService.fetchTripById(widget.tripId, allowUnauthenticated: true);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi khi tải thông tin: $e')),
            );
          }
        }
      });
    }

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      final arguments = ModalRoute.of(context)!.settings.arguments;
      String? tripId;

      if (arguments is String) {
        tripId = arguments;
      } else if (arguments is Map<String, dynamic>) {
        tripId = arguments['_id'] as String?;
      } else {
        print('Invalid tripId format: $arguments');
        return;
      }

      if (tripId != null && tripId != _tripId) {
        _tripId = tripId;
        Future.microtask(() async {
          final tripService = Provider.of<TripService>(context, listen: false);
          try {
            await tripService.fetchTripById(tripId!, allowUnauthenticated: true);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi khi tải thông tin chuyến đi: $e')),
              );
            }
          }
        });
      }
    }

    void _promptLogin(BuildContext context) {
      Navigator.pushNamed(context, '/auth/login_prompt');
    }

    Future<void> _navigateToSeatSelection(String tripId, String? userId) async {
      if (userId == null) {
        _promptLogin(context);
        return;
      }

      final tripService = Provider.of<TripService>(context, listen: false);
      final trip = tripService.trips.firstWhere(
            (t) => t.id == tripId,
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
      final vehicleId = trip.vehicle_id;

      final selectedSeatId = await Navigator.pushNamed(
        context,
        '/seat',
        arguments: {'tripId': tripId, 'vehicleId': vehicleId},
      );

      if (selectedSeatId != null && selectedSeatId is String && mounted) {
        setState(() => _isBooking = true);
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đặt vé thành công!', style: GoogleFonts.poppins()),
              backgroundColor: primaryColor,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đặt vé thất bại: $e')),
          );
        } finally {
          setState(() => _isBooking = false);
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      final authService = Provider.of<AuthService>(context);
      final isLoggedIn = authService.currentUser != null;

      if (_tripId == null || _tripId!.isEmpty) {
        return Scaffold(
          body: Center(
            child: Text(
              'ID chuyến đi không hợp lệ',
              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        );
      }

      return Theme(
        data: Theme.of(context).copyWith(
          primaryColor: primaryColor,
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            secondary: const Color(0xFF5B9EE5),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Consumer<TripService>(
              builder: (context, tripService, _) {
                final trip = tripService.trips.firstWhere(
                      (t) => t.id == _tripId,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      trip.vehicle_id.isNotEmpty ? trip.vehicle_id : 'Chi tiết chuyến đi',
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
            centerTitle: true,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Consumer2<TripService, LocationService>(
            builder: (context, tripService, locationService, _) {
              if (tripService.isLoading) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }

              final trip = tripService.trips.firstWhere(
                    (t) => t.id == _tripId,
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

              if (trip.id.isEmpty) {
                return Center(
                  child: Text(
                    'Không tìm thấy thông tin chuyến đi',
                    style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 16),
                  ),
                );
              }

              final location = locationService.locations.firstWhere(
                    (loc) => loc.id == trip.vehicle_id,
                orElse: () => Location(id: '', location: 'Không xác định', contact_phone: ''),
              );

              final userId = authService.currentUser?.id;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isLoggedIn)
                        Center(
                          child: Text(
                            'Vui lòng đăng nhập để đặt vé',
                            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 16),
                          ),
                        ),
                      const SizedBox(height: 50),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thông tin chuyến đi',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                leading: const Icon(Icons.location_on, color: primaryColor),
                                title: Text('Địa điểm: ${location.location}',
                                    style: GoogleFonts.poppins(fontSize: 16)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.arrow_forward, color: primaryColor),
                                title: Text('Điểm đi: ${trip.departure_location}',
                                    style: GoogleFonts.poppins(fontSize: 16)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.arrow_back, color: primaryColor),
                                title: Text('Điểm đến: ${trip.arrival_location}',
                                    style: GoogleFonts.poppins(fontSize: 16)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.access_time, color: primaryColor),
                                title: Text(
                                  'Thời gian đi: ${DateFormat('HH:mm dd/MM/yyyy').format(trip.departure_time)}',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.access_time_filled, color: primaryColor),
                                title: Text(
                                  'Thời gian đến: ${DateFormat('HH:mm dd/MM/yyyy').format(trip.arrival_time)}',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.attach_money, color: primaryColor),
                                title: Text('Giá: ${trip.price.toStringAsFixed(0)} VNĐ',
                                    style: GoogleFonts.poppins(fontSize: 16)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.directions_bus, color: primaryColor),
                                title: Text('Loại xe: ${trip.vehicle_id}',
                                    style: GoogleFonts.poppins(fontSize: 16)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.event_seat, color: primaryColor),
                                title: Text('Tổng ghế: ${trip.totalSeats}',
                                    style: GoogleFonts.poppins(fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        opacity: _isBooking ? 0.7 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed: _isBooking
                              ? null
                              : () => _navigateToSeatSelection(_tripId!, userId),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            elevation: 3,
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
                            isLoggedIn ? 'Chọn ghế' : 'Đăng nhập để chọn ghế',
                            style: GoogleFonts.montserrat(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }