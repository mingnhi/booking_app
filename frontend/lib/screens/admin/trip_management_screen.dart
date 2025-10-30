import 'package:flutter/material.dart';
import 'package:frontend/screens/admin/trip_create_form.dart';
import 'package:frontend/screens/admin/trip_edit_form.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/models/trip.dart'; // Thêm import cho model Trip
import 'package:frontend/services/location_service.dart'; // Thêm import cho LocationService
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TripManagementScreen extends StatefulWidget {
  const TripManagementScreen({Key? key}) : super(key: key);

  @override
  _TripManagementScreenState createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen> {
  final _storage = const FlutterSecureStorage();
  List<Trip> trips = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute('/admin/trip');
    _loadTrips();
    Provider.of<LocationService>(context, listen: false).fetchLocations();
  }

  void _saveCurrentRoute(String route) async {
    await _storage.write(key: 'lastAdminRoute', value: route);
  }

  Future<void> _loadTrips() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      final fetchedTripsData = await adminService.getTrips();
      final List<Trip> fetchedTrips =
          fetchedTripsData.map((tripData) {
            return Trip.fromJson(tripData);
          }).toList();
      setState(() {
        trips = fetchedTrips;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getLocationName(String locationId) async {
    if (locationId.isEmpty) {
      return 'N/A';
    }

    try {
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );
      final locations = locationService.locations;

      for (var loc in locations) {
        if (loc.id == locationId) {
          return loc.location;
        }
      }

      return locationId;
    } catch (e) {
      print('Error getting location name: $e');
      return locationId;
    }
  }

  // Phương thức hiển thị dialog xác nhận xóa
  void _showDeleteConfirmation(BuildContext context, String tripId) {
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Xác nhận xóa',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'Bạn có chắc chắn muốn xóa chuyến đi này không?',
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Hủy', style: GoogleFonts.poppins()),
                  ),
                  ElevatedButton(
                    onPressed:
                        isSubmitting
                            ? null
                            : () async {
                              setState(() {
                                isSubmitting = true;
                              });

                              try {
                                final adminService = Provider.of<AdminService>(
                                  context,
                                  listen: false,
                                );
                                final success = await adminService.deleteTrip(
                                  tripId,
                                );
                                Navigator.of(context).pop();

                                if (success) {
                                  // Hiển thị thông báo thành công
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã xóa chuyến đi thành công',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  // Tải lại danh sách chuyến đi
                                  _loadTrips();
                                } else {
                                  // Hiển thị thông báo lỗi
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Không thể xóa chuyến đi',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Hiển thị thông báo lỗi
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Lỗi: ${e.toString()}',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                setState(() {
                                  isSubmitting = false;
                                });
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(
                      'Xóa chuyến đi',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Phương thức hiển thị chi tiết chuyến đi
  void _showTripDetails(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (context) {
        final formatter = DateFormat('dd/MM/yyyy HH:mm');
        bool isEditing = false;
        bool isSubmitting = false;

        // Controllers cho các trường có thể chỉnh sửa
        final priceController = TextEditingController(
          text: trip.price.toString(),
        );
        final distanceController = TextEditingController(
          text: trip.distance.toString(),
        );
        final totalSeatsController = TextEditingController(
          text: trip.totalSeats.toString(),
        );

        // Các giá trị ban đầu - lưu ý rằng departure_location và arrival_location là tên địa điểm, không phải ID
        String departureLocationName = trip.departure_location;
        String arrivalLocationName = trip.arrival_location;
        String vehicleId = trip.vehicle_id;
        DateTime departureTime = trip.departure_time;
        DateTime arrivalTime = trip.arrival_time;

        return StatefulBuilder(
          builder: (context, setState) {
            final locationService = Provider.of<LocationService>(
              context,
              listen: false,
            );
            final locations = locationService.locations;

            // Tìm ID dựa trên tên địa điểm
            String? departureLocationId;
            String? arrivalLocationId;

            // Tìm ID của địa điểm dựa trên tên
            if (locations.isNotEmpty) {
              // Tìm địa điểm có tên trùng với departure_location
              final departureLocation = locations.firstWhere(
                (loc) =>
                    loc.location.toUpperCase() ==
                    departureLocationName.toUpperCase(),
                orElse: () => locations.first,
              );
              departureLocationId = departureLocation.id;

              // Tìm địa điểm có tên trùng với arrival_location
              final arrivalLocation = locations.firstWhere(
                (loc) =>
                    loc.location.toUpperCase() ==
                    arrivalLocationName.toUpperCase(),
                orElse: () => locations.first,
              );
              arrivalLocationId = arrivalLocation.id;
            } else {
              // Nếu danh sách địa điểm trống, gán giá trị mặc định
              departureLocationId = '';
              arrivalLocationId = '';
            }

            // Hàm lưu thay đổi
            Future<void> saveChanges() async {
              setState(() {
                isSubmitting = true;
              });

              try {
                final adminService = Provider.of<AdminService>(
                  context,
                  listen: false,
                );

                // Lấy tên địa điểm từ ID đã chọn
                final selectedDepartureLocation = locations.firstWhere(
                  (loc) => loc.id == departureLocationId,
                  orElse: () => locations.first,
                );

                final selectedArrivalLocation = locations.firstWhere(
                  (loc) => loc.id == arrivalLocationId,
                  orElse: () => locations.first,
                );

                final tripData = {
                  'departure_location':
                      selectedDepartureLocation.location, // Lưu tên địa điểm
                  'arrival_location':
                      selectedArrivalLocation.location, // Lưu tên địa điểm
                  'vehicle_id': vehicleId,
                  'departure_time': departureTime.toUtc().toIso8601String(),
                  'arrival_time': arrivalTime.toUtc().toIso8601String(),
                  'price': double.parse(priceController.text),
                  'distance': double.parse(distanceController.text),
                  'total_seats': int.parse(totalSeatsController.text),
                };

                await adminService.updateTrip(trip.id, tripData);

                if (context.mounted) {
                  Navigator.of(context).pop(true); // Đóng dialog và trả về true

                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cập nhật chuyến đi thành công',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Lỗi: ${e.toString()}',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (context.mounted) {
                  setState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            // Hàm chọn ngày giờ
            Future<void> selectDateTime(bool isDeparture) async {
              final initialDate = isDeparture ? departureTime : arrivalTime;
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );

              if (pickedDate != null) {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initialDate),
                );

                if (pickedTime != null && context.mounted) {
                  setState(() {
                    final newDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );

                    if (isDeparture) {
                      departureTime = newDateTime;
                    } else {
                      arrivalTime = newDateTime;
                    }
                  });
                }
              }
            }

            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Chỉnh sửa ch uyến đi'
                    : 'Chi tiết chuyến đi',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailItem('ID:', trip.id),

                    if (!isEditing) ...[
                      // Hiển thị chi tiết khi không ở chế độ chỉnh sửa
                      FutureBuilder<String>(
                        future: _getLocationName(trip.departure_location),
                        builder: (context, snapshot) {
                          return _buildDetailItem(
                            'Điểm đi:',
                            snapshot.data ?? trip.departure_location,
                          );
                        },
                      ),
                      FutureBuilder<String>(
                        future: _getLocationName(trip.arrival_location),
                        builder: (context, snapshot) {
                          return _buildDetailItem(
                            'Điểm đến:',
                            snapshot.data ?? trip.arrival_location,
                          );
                        },
                      ),
                      _buildDetailItem(
                        'Thời gian đi:',
                        formatter.format(trip.departure_time),
                      ),
                      _buildDetailItem(
                        'Thời gian đến:',
                        formatter.format(trip.arrival_time),
                      ),
                      _buildDetailItem(
                        'Giá vé:',
                        '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(trip.price)}',
                      ),
                      _buildDetailItem('Loại xe:', trip.vehicle_id),
                      _buildDetailItem('Tổng số ghế:', '${trip.totalSeats}'),
                      _buildDetailItem('Khoảng cách:', '${trip.distance} km'),
                      if (trip.createdAt != null)
                        _buildDetailItem(
                          'Ngày tạo:',
                          formatter.format(trip.createdAt!),
                        ),
                      if (trip.updatedAt != null)
                        _buildDetailItem(
                          'Cập nhật lần cuối:',
                          formatter.format(trip.updatedAt!),
                        ),
                    ] else ...[
                      // Hiển thị form chỉnh sửa
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Điểm đi',
                            border: OutlineInputBorder(),
                          ),
                          value: departureLocationId,
                          items:
                              locations.map((location) {
                                return DropdownMenuItem<String>(
                                  value: location.id,
                                  child: Text(location.location),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                departureLocationId = value;
                              });
                            }
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Điểm đến',
                            border: OutlineInputBorder(),
                          ),
                          value: arrivalLocationId,
                          items:
                              locations.map((location) {
                                return DropdownMenuItem<String>(
                                  value: location.id,
                                  child: Text(location.location),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                arrivalLocationId = value;
                              });
                            }
                          },
                        ),
                      ),

                      ListTile(
                        title: Text('Thời gian đi'),
                        subtitle: Text(formatter.format(departureTime)),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () => selectDateTime(true),
                      ),

                      ListTile(
                        title: Text('Thời gian đến'),
                        subtitle: Text(formatter.format(arrivalTime)),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () => selectDateTime(false),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: priceController,
                          decoration: InputDecoration(
                            labelText: 'Giá vé',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: distanceController,
                          decoration: InputDecoration(
                            labelText: 'Khoảng cách (km)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: totalSeatsController,
                          decoration: InputDecoration(
                            labelText: 'Tổng số ghế',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!isEditing) ...[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Đóng', style: GoogleFonts.poppins()),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: Text('Sửa', style: GoogleFonts.poppins()),
                  ),
                ] else ...[
                  TextButton(
                    onPressed:
                        isSubmitting
                            ? null
                            : () {
                              setState(() {
                                isEditing = false;
                              });
                            },
                    child: Text('Hủy', style: GoogleFonts.poppins()),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : saveChanges,
                    child:
                        isSubmitting
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text('Lưu', style: GoogleFonts.poppins()),
                  ),
                ],
              ],
            );
          },
        );
      },
    ).then((result) {
      // Nếu có cập nhật thành công, tải lại danh sách chuyến đi
      if (result == true) {
        _loadTrips();
      }
    });
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  // Phương thức để mở màn hình chỉnh sửa chuyến đi
  void _editTrip(BuildContext context, String tripId) async {
    // Lưu tham chiếu đến BuildContext hiện tại
    final currentContext = context;
    final adminService = Provider.of<AdminService>(
      currentContext,
      listen: false,
    );

    setState(() {
      isLoading = true;
    });

    try {
      final tripData = await adminService.getTripDetail(tripId);

      // Kiểm tra mounted sau mỗi async operation
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // Sử dụng currentContext để push màn hình mới
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripEditForm(tripData: tripData),
        ),
      );

      if (result == true) {
        _loadTrips();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        error = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Phương thức để mở form tạo chuyến đi mới
  void _createNewTrip(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripCreateForm()),
    );
    if (result == true) {
      _loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error!,
                style: GoogleFonts.poppins(),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTrips,
              icon: const Icon(Icons.refresh),
              label: Text('Thử lại', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    }

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_bus_filled_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có chuyến đi nào',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _createNewTrip(context),
              icon: const Icon(Icons.add),
              label: Text('Thêm chuyến đi mới', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: ListView.builder(
          itemCount: trips.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final trip = trips[index];
            final formatter = DateFormat('dd/MM/yyyy HH:mm');

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<String>(
                            future: _getLocationName(trip.departure_location),
                            builder: (context, departureSnapshot) {
                              final departureName =
                                  departureSnapshot.data ??
                                  trip.departure_location;
                              return FutureBuilder<String>(
                                future: _getLocationName(trip.arrival_location),
                                builder: (context, arrivalSnapshot) {
                                  final arrivalName =
                                      arrivalSnapshot.data ??
                                      trip.arrival_location;
                                  return Text(
                                    '$departureName → $arrivalName',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: 'đ',
                          ).format(trip.price),
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Khởi hành',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                formatter.format(trip.departure_time),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đến nơi',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                formatter.format(trip.arrival_time),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loại xe',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                trip.vehicle_id,
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Số ghế',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${trip.totalSeats}',
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showTripDetails(context, trip),
                          icon: const Icon(Icons.visibility),
                          label: Text('Chi tiết', style: GoogleFonts.poppins()),
                        ),
                        // const SizedBox(width: 8),
                        // ElevatedButton.icon(
                        //   onPressed: () => _editTrip(context, trip.id),
                        //   icon: const Icon(Icons.edit),
                        //   label: Text('Sửa', style: GoogleFonts.poppins()),
                        // ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed:
                              () => _showDeleteConfirmation(context, trip.id),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewTrip(context),
        child: const Icon(Icons.add),
        tooltip: 'Thêm chuyến đi mới',
      ),
    );
  }
}
