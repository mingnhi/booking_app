import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../services/location_service.dart';
import '../../services/vehicle_service.dart';

class TripEditForm extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const TripEditForm({Key? key, required this.tripData}) : super(key: key);

  @override
  _TripEditFormState createState() => _TripEditFormState();
}

class _TripEditFormState extends State<TripEditForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _priceController = TextEditingController();
  final _distanceController = TextEditingController();
  final _totalSeatsController = TextEditingController();

  // Trip data
  String _departureLocationId = '';
  String _arrivalLocationId = '';
  String _vehicleID = '';
  DateTime _departureTime = DateTime.now();
  DateTime _arrivalTime = DateTime.now().add(const Duration(hours: 2));

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    Provider.of<LocationService>(context, listen: false).fetchLocations();
    Provider.of<VehicleService>(context, listen: false).fetchVehicles();
  }

  void _initializeFormData() {
    final tripData = widget.tripData;

    _departureLocationId = tripData['departure_location']?['_id'] ?? tripData['departure_location'] ?? '';
    _arrivalLocationId = tripData['arrival_location']?['_id'] ?? tripData['arrival_location'] ?? '';
    _vehicleID = tripData['vehicle_id']?['_id'] ?? tripData['vehicle_id'] ?? '';
    _priceController.text = tripData['price']?.toString() ?? '';
    _distanceController.text = tripData['distance']?.toString() ?? '';
    _totalSeatsController.text = tripData['total_seats']?.toString() ?? '';

    if (tripData['departure_time'] != null) {
      _departureTime = DateTime.parse(tripData['departure_time']);
    }

    if (tripData['arrival_time'] != null) {
      _arrivalTime = DateTime.parse(tripData['arrival_time']);
    }
  }

  Future<void> _selectDepartureDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _departureTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          0,
          0,
          0,
        );

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
      initialDate: _arrivalTime.isBefore(_departureTime)
          ? _departureTime.add(const Duration(days: 1))
          : _arrivalTime,
      firstDate: _departureTime,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      setState(() {
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

  Future<Map<String, dynamic>> _saveTrip() async {
    if (!_formKey.currentState!.validate()) {
      return {'success': false, 'message': 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.'};
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);

      final departureDate = DateTime(
        _departureTime.year,
        _departureTime.month,
        _departureTime.day,
      ).toUtc();

      final arrivalDate = DateTime(
        _arrivalTime.year,
        _arrivalTime.month,
        _arrivalTime.day,
      ).toUtc();

      final tripData = {
        'departure_location': _departureLocationId,
        'arrival_location': _arrivalLocationId,
        'vehicle_id': _vehicleID,
        'departure_time': departureDate.toIso8601String(),
        'arrival_time': arrivalDate.toIso8601String(),
        'price': double.parse(_priceController.text),
        'distance': double.parse(_distanceController.text),
        'total_seats': int.parse(_totalSeatsController.text),
      };

      print('Trip data to be sent: $tripData');

      await adminService.updateTrip(widget.tripData['_id'], tripData);

      return {'success': true, 'message': 'Cập nhật chuyến đi thành công'};
    } catch (e) {
      String errorMessage = 'Đã xảy ra lỗi khi cập nhật chuyến đi.';
      if (e.toString().contains('401')) {
        errorMessage = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
      }
      return {'success': false, 'message': errorMessage};
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _distanceController.dispose();
    _totalSeatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final vehicleService = Provider.of<VehicleService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa chuyến đi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<LocationService, VehicleService>(
        builder: (context, locationService, vehicleService, _) {
          if (locationService.isLoading || vehicleService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final locations = locationService.locations;
          final vehicles = vehicleService.vehicles;

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
                            prefixIcon: Icon(Icons.directions_bus),
                          ),
                          value: _vehicleID.isNotEmpty ? _vehicleID : null,
                          items: vehicles.map((vehicle) {
                            return DropdownMenuItem<String>(
                              value: vehicle.id,
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
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Điểm đi',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          value: _departureLocationId.isNotEmpty ? _departureLocationId : null,
                          items: locations.map((location) {
                            return DropdownMenuItem<String>(
                              value: location.id,
                              child: Text(location.location),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && mounted) {
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
                          value: _arrivalLocationId.isNotEmpty ? _arrivalLocationId : null,
                          items: locations.map((location) {
                            return DropdownMenuItem<String>(
                              value: location.id,
                              child: Text(location.location),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && mounted) {
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
                            DateFormat('dd/MM/yyyy').format(_departureTime),
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
                            DateFormat('dd/MM/yyyy').format(_arrivalTime),
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
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập khoảng cách';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Khoảng cách phải là số';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Khoảng cách phải lớn hơn 0';
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
                  onPressed: _isLoading
                      ? null
                      : () async {
                    final result = await _saveTrip();
                    if (mounted) {
                      Navigator.of(context).pop(result);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : Text(
                    'Lưu thay đổi',
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