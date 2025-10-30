import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../models/trip.dart';
import '../home/customer_nav_bar.dart';
import '../../services/seat_service.dart';

class TripListScreen extends StatefulWidget {
  final List<Trip> trips;
  final String? departureId;
  final String? arrivalId;

  const TripListScreen({
    super.key,
    required this.trips,
    this.departureId,
    this.arrivalId,
  });

  @override
  _TripListScreenState createState() => _TripListScreenState();
} 

class _TripListScreenState extends State<TripListScreen> {
  int _selectedIndex = 1; // Mặc định là TripListScreen

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    final arguments = {
      'departureId': widget.departureId,
      'arrivalId': widget.arrivalId,
    };
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home', arguments: arguments);
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/trip/search', arguments: arguments);
    } else if (authService.currentUser == null) {
      Navigator.pushNamed(context, '/auth/login_prompt');
    } else {
      switch (index) {
        case 2:
          Navigator.pushReplacementNamed(context, '/tickets', arguments: arguments);
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/auth/profile', arguments: arguments);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LocationService>(
          builder: (context, locationService, _) {
            String departureName = 'Không xác định';
            String arrivalName = 'Không xác định';
            try {
              if (widget.departureId != null) {
                departureName = locationService.locations
                    .firstWhere((loc) => loc.id == widget.departureId)
                    .location;
              }
              if (widget.arrivalId != null) {
                arrivalName = locationService.locations
                    .firstWhere((loc) => loc.id == widget.arrivalId)
                    .location;
              }
            } catch (e) {
              print('Lỗi khi ánh xạ ID địa điểm: $e');
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  departureName,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                SizedBox(width: 5), // khoảng cách giữa text và icon
                Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: Colors.white, // hoặc đổi màu tùy ý bạn
                ),
                SizedBox(width: 5),
                Text(
                  arrivalName,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ],
            );

          },
        ),
        backgroundColor: const Color(0xFF2474E5),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade300, // Set body background color
      body: Consumer2<LocationService, SeatService>(
        builder: (context, locationService, seatService, _) {
          if (locationService.isLoading || seatService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.trips.isEmpty) {
            return Center(
              child: Text(
                'Không tìm thấy chuyến đi phù hợp.',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: widget.trips.length,
            itemBuilder: (context, index) {
              final trip = widget.trips[index];

              String departureName = 'Không xác định';
              String arrivalName = 'Không xác định';
              try {
                if (widget.departureId != null) {
                  departureName = locationService.locations
                      .firstWhere((loc) => loc.id == widget.departureId)
                      .location;
                }
                if (widget.arrivalId != null) {
                  arrivalName = locationService.locations
                      .firstWhere((loc) => loc.id == widget.arrivalId)
                      .location;
                }
              } catch (e) {
                print('Lỗi khi ánh xạ ID địa điểm: $e');
              }

              // Tính thời gian hành trình
              final duration = trip.arrival_time.difference(trip.departure_time);
              final hours = duration.inHours;
              final minutes = duration.inMinutes % 60;
              final durationText = '$hours giờ ${minutes > 0 ? '$minutes phút' : ''}';

              // Tính số ghế trống
              final bookedSeats = seatService.seats.where((seat) => seat.tripId == trip.id && seat.statusSeat == 'BOOKED').length;
              final availableSeatsCount = trip.totalSeats - bookedSeats;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/trip/detail/id',
                      arguments: trip.id,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Khung 1: Thời gian, địa điểm, giá tiền, chỗ trống
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(trip.departure_time),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      durationText,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormat('HH:mm').format(trip.arrival_time),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 13,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF2474E5), // Màu xanh
                                              ),
                                            ),
                                            Container(
                                              width: 4,
                                              height: 4,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          departureName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                    ), // Thanh dọc
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                            Icons.location_on, color: Colors.redAccent, size: 19
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          arrivalName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(trip.price)}đ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '$availableSeatsCount chỗ trống',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(
                          color: 	Color(0xFFCCCCCC),
                          thickness: 1,
                          height: 0, // Đảm bảo không có khoảng cách dọc thêm
                        ), // Thanh ngang giữa Khung 1 và Khung 2
                        const SizedBox(height: 12),
                        // Khung 2: Hình ảnh và thông tin xe
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
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
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  '${trip.vehicle_id} - ${trip.totalSeats}',
                                  style: GoogleFonts.poppins(
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
                        // Khung 3: Các thông tin còn lại
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'FLASH SALE',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Vexere',
                                            style: GoogleFonts.poppins(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Không cần thanh toán trước',
                                              style: GoogleFonts.poppins(
                                                color: Colors.black87,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.local_taxi,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Đón trả tận nơi',
                                              style: GoogleFonts.poppins(
                                                color: Colors.black87,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.bolt,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Xác nhận chỗ ngay lập tức',
                                              style: GoogleFonts.poppins(
                                                color: Colors.black87,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.gps_fixed,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Theo dõi hành trình xe',
                                              style: GoogleFonts.poppins(
                                                color: Colors.black87,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Positioned(
                                //   right: 0,
                                //   bottom: 0,
                                //   // child: ElevatedButton(
                                //   //   onPressed: () {
                                //   //     // Navigate to trip detail screen with trip ID
                                //   //     Navigator.pushNamed(
                                //   //       context,
                                //   //       '/trip/detail',
                                //   //       arguments: trip.id,
                                //   //     );
                                //   //   },
                                //   //   style: ElevatedButton.styleFrom(
                                //   //     padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                //   //     backgroundColor: const Color(0xFFFFD333),
                                //   //     shape: RoundedRectangleBorder(
                                //   //       borderRadius: BorderRadius.circular(8),
                                //   //     ),
                                //   //     elevation: 2,
                                //   //   ),
                                //   //   child: Text(
                                //   //     'Chọn chỗ',
                                //   //     style: GoogleFonts.montserrat(
                                //   //       color: Colors.black,
                                //   //       fontSize: 15,
                                //   //       fontWeight: FontWeight.bold,
                                //   //     ),
                                //   //   ),
                                //   // ),
                                // ),
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
          );
        },
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}