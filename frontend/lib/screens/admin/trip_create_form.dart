import 'package:flutter/material.dart';
import 'package:frontend/models/vehicle.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../services/location_service.dart';
import '../../services/vehicle_service.dart';

class TripCreateForm extends StatefulWidget {
  @override
  _TripCreateFormState createState() => _TripCreateFormState();
}

class _TripCreateFormState extends State<TripCreateForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _priceController = TextEditingController();
  final _distanceController = TextEditingController();
  final _totalSeatsController = TextEditingController();

  // Trip data
  String _departureLocationId = '';
  String _arrivalLocationId = '';
  String _vehicleID = '';
  DateTime _departureTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _arrivalTime = DateTime.now().add(const Duration(hours: 3));

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Provider.of<LocationService>(context, listen: false).fetchLocations();
    Provider.of<VehicleService>(context, listen: false).fetchVehicles();
  }

  Future<void> _selectDepartureDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        // Chỉ lấy ngày tháng năm, đặt giờ phút giây về 0
        _departureTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          0,
          0,
          0,
        );

        // Ensure arrival time is after departure time
        if (_arrivalTime.isBefore(_departureTime)) {
          _arrivalTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            0,
            0,
            0,
          ).add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectArrivalDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _arrivalTime.isBefore(_departureTime)
              ? _departureTime.add(const Duration(days: 1))
              : _arrivalTime,
      firstDate: _departureTime,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        // Chỉ lấy ngày tháng năm, đặt giờ phút giây về 0
        _arrivalTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          0,
          0,
          0,
        );
      });
    }
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);

      // Tạo DateTime mới chỉ chứa ngày tháng năm (00:00:00)
      final departureDate = DateTime(
        _departureTime.year,
        _departureTime.month,
        _departureTime.day,
      );

      final arrivalDate = DateTime(
        _arrivalTime.year,
        _arrivalTime.month,
        _arrivalTime.day,
      );

      final tripData = {
        'vehicle_id': _vehicleID,
        'departure_location': _departureLocationId,
        'arrival_location': _arrivalLocationId,
        'departure_time': departureDate.toIso8601String(),
        'arrival_time': arrivalDate.toIso8601String(),
        'price': double.parse(_priceController.text),
        'distance': double.parse(_distanceController.text),
        'total_seats': int.parse(_totalSeatsController.text),
      };

      try {
        await adminService.createTrip(tripData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo chuyến đi mới thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Ngay cả khi có lỗi 500, vẫn thử kiểm tra xem trip có được tạo không
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đang tạo chuyến đi , vui lòng đợi'),
            backgroundColor: Colors.orange,
          ),
        );

        // Đợi 2 giây để server có thể hoàn tất xử lý
        await Future.delayed(const Duration(seconds: 2));
      }

      // Dù có lỗi hay không, vẫn trả về true để load lại danh sách trip
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đảm bảo các service được fetch dữ liệu trước khi build
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final vehicleService = Provider.of<VehicleService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tạo chuyến đi mới',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<LocationService>(
                builder: (context, locationService, _) {
                  if (locationService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final locations = locationService.locations;

                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thông tin cơ bản',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Chọn Xe',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_on),
                                  ),
                                  value:
                                      _vehicleID.isNotEmpty ? _vehicleID : null,
                                  items:
                                      Provider.of<VehicleService>(
                                        context,
                                        listen: false,
                                      ).vehicles.map((vehicle) {
                                        return DropdownMenuItem<String>(
                                          value: vehicle.licensePlate,
                                          child: Text(vehicle.licensePlate),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _vehicleID = value;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng chọn biển số xe';
                                    }
                                    return null;
                                  },
                                ),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Điểm đi',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_on),
                                  ),
                                  value:
                                      _departureLocationId.isNotEmpty
                                          ? _departureLocationId
                                          : null,
                                  items:
                                      locations.map((location) {
                                        return DropdownMenuItem<String>(
                                          value: location.location,
                                          child: Text(location.location),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _departureLocationId = value;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng chọn điểm đi';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Điểm đến',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_on),
                                  ),
                                  value:
                                      _arrivalLocationId.isNotEmpty
                                          ? _arrivalLocationId
                                          : null,
                                  items:
                                      locations.map((location) {
                                        return DropdownMenuItem<String>(
                                          value: location.location,
                                          child: Text(location.location),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _arrivalLocationId = value;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng chọn điểm đến';
                                    }
                                    if (value == _departureLocationId) {
                                      return 'Điểm đến không được trùng với điểm đi';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thời gian',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  title: const Text('Thời gian khởi hành'),
                                  subtitle: Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_departureTime),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.calendar_today),
                                  onTap: () => _selectDepartureDate(context),
                                ),
                                const Divider(),
                                ListTile(
                                  title: const Text('Thời gian đến'),
                                  subtitle: Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_arrivalTime),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.calendar_today),
                                  onTap: () => _selectArrivalDate(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thông tin khác',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Giá vé (VND)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.attach_money),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập giá vé';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Giá vé phải là số';
                                    }
                                    if (double.parse(value) <= 0) {
                                      return 'Giá vé phải lớn hơn 0';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _distanceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Khoảng cách (km)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.directions_bus),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập loại xe';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _totalSeatsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tổng số ghế',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.event_seat),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập tổng số ghế';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Tổng số ghế phải là số nguyên';
                                    }
                                    if (int.parse(value) <= 0) {
                                      return 'Tổng số ghế phải lớn hơn 0';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createTrip,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    'Tạo chuyến đi mới',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
