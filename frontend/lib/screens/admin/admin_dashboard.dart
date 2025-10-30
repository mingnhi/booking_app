import 'package:flutter/material.dart';
import 'package:frontend/screens/admin/location_management_screen.dart';
import 'package:frontend/screens/admin/seat_management_screen.dart';
import 'package:frontend/screens/admin/trip_management_screen.dart';
import 'package:frontend/screens/admin/user_management_screen.dart';
import 'package:frontend/screens/admin/ticket_management_screen.dart';
import 'package:frontend/screens/admin/payment_management_screen.dart';
import 'package:frontend/screens/admin/vehicle_management_screen.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  bool _isInit = false;

  // Sử dụng late để khởi tạo các màn hình khi cần thiết
  late final List<Widget> _screens;

  @override
  bool get wantKeepAlive => true; // Giữ trạng thái khi chuyển tab

  @override
  void initState() {
    super.initState();

    // Khởi tạo các màn hình trong initState để tránh tạo lại mỗi khi build
    _screens = [
      const TripManagementScreen(),
      const TicketManagementScreen(),
      const UserManagementScreen(),
      const SeatManagementScreen(),
      const LocationManagementScreen(),
      const PaymentManagementScreen(),
      const VehicleManagementScreen(),
    ];

    // Kiểm tra quyền admin khi vào trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInit && mounted) {
        _isInit = true;
        AuthUtils.checkAdminAccess(context);
      }
    });
  }

  final List<String> _titles = [
    'Quản lý chuyến đi',
    'Quản lý vé',
    'Quản lý người dùng',
    'Quản lý ghế',
    'Quản lý địa điểm',
    'Quản lý thanh toán',
    'Quản lý phương tiện',
  ];

  @override
  Widget build(BuildContext context) {
    // Gọi super.build khi sử dụng AutomaticKeepAliveClientMixin
    super.build(context);

    return WillPopScope(
      onWillPop: () async {
        // Xử lý khi người dùng nhấn nút back
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false; // Không thoát ứng dụng, chỉ quay lại tab đầu tiên
        }
        return true; // Cho phép thoát ứng dụng
      },
      child: ScaffoldMessenger(
        child: Scaffold(
          appBar: AppBar(
            title: Text(_titles[_selectedIndex]),
            backgroundColor: Colors.blue,
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.blue),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 30,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Admin Dashboard',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: const Text('Quản lý chuyến đi'),
                  selected: _selectedIndex == 0,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.confirmation_number),
                  title: const Text('Quản lý vé'),
                  selected: _selectedIndex == 1,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Quản lý người dùng'),
                  selected: _selectedIndex == 2,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_seat),
                  title: const Text('Quản lý ghế'),
                  selected: _selectedIndex == 3,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Quản lý địa điểm'),
                  selected: _selectedIndex == 4,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 4;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Quản lý thanh toán'),
                  selected: _selectedIndex == 5,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 5;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: const Text('Quản lý phương tiện'),
                  selected: _selectedIndex == 6,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 6;
                    });
                    Navigator.pop(context);
                  },
                ),

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Về trang chủ'),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Đăng xuất'),
                  onTap: () {
                    // Xử lý đăng xuất
                    Navigator.pushReplacementNamed(context, '/auth/login');
                  },
                ),
              ],
            ),
          ),
          body: IndexedStack(index: _selectedIndex, children: _screens),
        ),
      ),
    );
  }
}
