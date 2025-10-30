import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/location/location_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/location.dart';
import '../../services/trip_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../home/customer_nav_bar.dart';
import '../../models/trip.dart';

// Custom Clipper để tạo hình dạng góc nhọn
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(0, size.height - 50);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key});

  @override
  _TripSearchScreenState createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen>
    with SingleTickerProviderStateMixin {
  String? _departureId;
  String? _arrivalId;
  String? _departureLocationName;
  String? _arrivalLocationName;
  DateTime? _departureTime;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  int _selectedIndex = 1; // Mặc định là TripSearchScreen

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: const Color(0xFF2474E5).withOpacity(0.8),
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );
    _animationController!.forward();

    // Khởi tạo locale cho 'vi_VN'
    initializeDateFormatting('vi_VN', null).then((_) {
      Future.microtask(() async {
        if (mounted) {
          final locationService = Provider.of<LocationService>(context, listen: false);
          await locationService.fetchLocations(allowUnauthenticated: true);
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      // Đã ở TripSearchScreen
    } else if (authService.currentUser == null) {
      Navigator.pushNamed(context, '/auth/login_prompt');
    } else {
      switch (index) {
        case 2:
          Navigator.pushReplacementNamed(context, '/tickets');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/auth/profile');
          break;
      }
    }
  }

  Future<void> _searchTrips() async {
    final tripService = Provider.of<TripService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    try {
      if (locationService.locations.isEmpty) {
        throw Exception('Không có danh sách địa điểm để tìm kiếm');
      }

      final departureLocation = _departureId != null
          ? locationService.locations
          .firstWhere(
            (loc) => loc.id == _departureId,
        orElse: () => throw Exception('Không tìm thấy điểm đi với ID: $_departureId'),
      )
          .location
          : null;
      final arrivalLocation = _arrivalId != null
          ? locationService.locations
          .firstWhere(
            (loc) => loc.id == _arrivalId,
        orElse: () => throw Exception('Không tìm thấy điểm đến với ID: $_arrivalId'),
      )
          .location
          : null;

      if (departureLocation == null || arrivalLocation == null) {
        throw Exception('Vui lòng chọn điểm đi và điểm đến');
      }

      final results = await tripService.searchTrips(
        departureLocation: departureLocation,
        arrivalLocation: arrivalLocation,
        departureTime: _departureTime,
        allowUnauthenticated: true,
      );

      // Lưu tìm kiếm gần đây
      if (_departureId != null && _arrivalId != null && results.isNotEmpty) {
        final tripId = results[0].id;
        tripService.addRecentSearch(
          _departureId!,
          _arrivalId!,
          _departureTime ?? DateTime.now(),
          tripId: tripId,
        );
      }

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/trip/list',
          arguments: {
            'trips': results,
            'departureId': _departureId,
            'arrivalId': _arrivalId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tìm kiếm chuyến đi: $e')),
        );
      }
    }
  }

  void _selectRecentSearch(Map<String, dynamic> search) async {
    final tripService = Provider.of<TripService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);

    try {
      // Get departure and arrival IDs from the recent search
      final departureId = search['departureId'] as String?;
      final arrivalId = search['arrivalId'] as String?;

      if (departureId == null || arrivalId == null) {
        throw Exception('Dữ liệu tìm kiếm gần đây không hợp lệ');
      }

      // Get departure and arrival locations
      final departureLocation = locationService.locations
          .firstWhere(
            (loc) => loc.id == departureId,
        orElse: () => throw Exception('Không tìm thấy điểm đi với ID: $departureId'),
      )
          .location;
      final arrivalLocation = locationService.locations
          .firstWhere(
            (loc) => loc.id == arrivalId,
        orElse: () => throw Exception('Không tìm thấy điểm đến với ID: $arrivalId'),
      )
          .location;

      // Perform a new search with the departure and arrival locations, without departureTime
      final results = await tripService.searchTrips(
        departureLocation: departureLocation,
        arrivalLocation: arrivalLocation,
        allowUnauthenticated: true,
      );

      // Navigate to TripListScreen with the search results
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/trip/list',
          arguments: {
            'trips': results,
            'departureId': departureId,
            'arrivalId': arrivalId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu tìm kiếm gần đây: $e')),
        );
      }
    }
  }

  Future<void> _selectLocation(bool isDeparture) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationListScreen(
          title: isDeparture ? 'Chọn Điểm Đi' : 'Chọn Điểm Đến',
          initialLocationId: isDeparture ? _departureId : _arrivalId,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (isDeparture) {
          _departureId = result['id'];
          _departureLocationName = result['location'];
        } else {
          _arrivalId = result['id'];
          _arrivalLocationName = result['location'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.white, // Solid white background
        child: SafeArea(
          top: true,
          bottom: false,
          child: Consumer3<TripService, LocationService, AuthService>(
            builder: (context, tripService, locationService, authService, _) {
              if (locationService.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (locationService.locations.isEmpty) {
                return Center(
                  child: Text(
                    'Không thể tải danh sách địa điểm.',
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              if (_fadeAnimation == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Triangular container with sharp corner
                  ClipPath(
                    clipper: TriangleClipper(),
                    child: Container(
                      width: double.infinity,
                      height: 300, // Adjusted to fit header content
                      color: const Color(0xFF2474E5), // Matches previous top color
                    ),
                  ),
                  // Existing UI elements overlapping the triangular container
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 35.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                'assets/images/vexere_logo.png',
                                height: 40,
                              ),
                              Text(
                                'Chào ${authService.currentUser?.fullName ?? "Khách"}!',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Text(
                            'Cam kết hoàn 150% nếu nhà xe không cung cấp dịch vụ vận chuyển (*)',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Card with search fields
                          Card(
                            elevation: 5,
                            shadowColor: const Color(0xFF2474E5).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFF2474E5), width: 1),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.directions_bus,
                                        color: Color(0xFF2474E5),
                                        size: 28,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Xe khách',
                                        style: GoogleFonts.poppins(
                                          color: Color(0xFF2474E5),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
                                    onTap: () => _selectLocation(true),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Điểm Đi',
                                        labelStyle: GoogleFonts.poppins(color: Colors.blueGrey.shade800),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(7),
                                          borderSide: const BorderSide(color: Color(0xFF2474E5)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(7),
                                          borderSide: const BorderSide(color: Color(0xFF2474E5), width: 2),
                                        ),
                                        prefixIcon: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF2474E5),
                                              ),
                                            ),
                                            Container(
                                              width: 10,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        _departureLocationName ?? 'Chọn điểm đi',
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
                                    onTap: () => _selectLocation(false),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Điểm Đến',
                                        labelStyle: GoogleFonts.poppins(color: Colors.blueGrey.shade800),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFF2474E5)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFF2474E5), width: 2),
                                        ),
                                        prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent, size: 30),
                                      ),
                                      child: Text(
                                        _arrivalLocationName ?? 'Chọn điểm đến',
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _departureTime = DateTime(picked.year, picked.month, picked.day);
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Ngày đi',
                                        labelStyle: GoogleFonts.poppins(color: Colors.blueGrey.shade800),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFF2474E5)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Color(0xFF2474E5), width: 2),
                                        ),
                                        prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF2474E5)),
                                      ),
                                      child: Text(
                                        _departureTime != null
                                            ? DateFormat('dd/MM/yyyy').format(_departureTime!)
                                            : 'Chọn ngày',
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Search button moved outside the Card
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _departureId != null && _arrivalId != null ? _searchTrips : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD333),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                elevation: 5,
                              ),
                              child: Text(
                                'Tìm kiếm',
                                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          // Updated horizontal row below the search button with text wrapping
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'Chắc chắn \ncó chỗ',
                                      style: GoogleFonts.montserrat(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.headset, color: Colors.green, size: 20),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      'Hỗ trợ \n'
                                          '24/7',
                                      style: GoogleFonts.montserrat(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.percent, color: Colors.green, size: 20),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      'Nhiều \nưu đãi',
                                      style: GoogleFonts.montserrat(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.attach_money, color: Colors.green, size: 20),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      'Thanh toán dễ dàng',
                                      style: GoogleFonts.montserrat(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Phần Tìm kiếm gần đây
                          if (tripService.recentSearches.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tìm kiếm gần đây',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: tripService.recentSearches.length,
                                itemBuilder: (context, index) {
                                  final search = tripService.recentSearches[index];
                                  final departureLoc = locationService.locations
                                      .firstWhere(
                                        (loc) => loc.id == search['departureId'],
                                    orElse: () => Location(id: '', location: 'Không rõ', contact_phone: ''),
                                  )
                                      .location;
                                  final arrivalLoc = locationService.locations
                                      .firstWhere(
                                        (loc) => loc.id == search['arrivalId'],
                                    orElse: () => Location(id: '', location: 'Không rõ', contact_phone: ''),
                                  )
                                      .location;

                                  return GestureDetector(
                                    onTap: () => _selectRecentSearch(search),
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(color: Color(0xFF2474E5), width: 1),
                                      ),
                                      elevation: 2,
                                      child: Container(
                                        width: 200,
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Stack(
                                                        alignment: Alignment.center,
                                                        children: [
                                                          Container(
                                                            width: 15,
                                                            height: 12,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: const Color(0xFF2474E5),
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
                                                      Expanded(
                                                        child: Text(
                                                          departureLoc,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.black,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: List.generate(3, (index) => const Icon(
                                                        Icons.circle,
                                                        size: 4,
                                                        color: Colors.grey,
                                                      )).map((dot) => Padding(
                                                        padding: const EdgeInsets.only(bottom: 2.0),
                                                        child: dot,
                                                      )).toList(),
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Stack(
                                                        alignment: Alignment.center,
                                                        children: [
                                                          Container(
                                                            width: 15,
                                                            height: 12,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: Colors.redAccent,
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
                                                      Expanded(
                                                        child: Text(
                                                          arrivalLoc,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.black,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 20,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}