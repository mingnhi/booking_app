import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../services/location_service.dart';

class TripCreateScreen extends StatefulWidget {
  @override
  _TripCreateScreenState createState() => _TripCreateScreenState();
}

class _TripCreateScreenState extends State<TripCreateScreen> {
  final _locationIdController = TextEditingController();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _priceController = TextEditingController();
  final _distanceController = TextEditingController();
  final _totalSeatsController = TextEditingController();
  DateTime _departureTime = DateTime.now();
  DateTime _arrivalTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    Provider.of<LocationService>(context, listen: false).fetchLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tạo chuyến đi')),
      body: Consumer<LocationService>(
        builder: (context, locationService, _) {
          if (locationService.isLoading)
            return Center(child: CircularProgressIndicator());
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView(
              children: [
                DropdownButton<String>(
                  hint: Text('Địa điểm'),
                  value:
                      _locationIdController.text.isNotEmpty
                          ? _locationIdController.text
                          : null,
                  items:
                      locationService.locations.map((loc) {
                        return DropdownMenuItem<String>(
                          value: loc.id,
                          child: Text(loc.location),
                        );
                      }).toList(),
                  onChanged:
                      (value) =>
                          setState(() => _locationIdController.text = value!),
                ),
                DropdownButton<String>(
                  hint: Text('Điểm đi'),
                  value:
                      _departureController.text.isNotEmpty
                          ? _departureController.text
                          : null,
                  items:
                      locationService.locations.map((loc) {
                        return DropdownMenuItem<String>(
                          value: loc.id,
                          child: Text(loc.location),
                        );
                      }).toList(),
                  onChanged:
                      (value) =>
                          setState(() => _departureController.text = value!),
                ),
                DropdownButton<String>(
                  hint: Text('Điểm đến'),
                  value:
                      _arrivalController.text.isNotEmpty
                          ? _arrivalController.text
                          : null,
                  items:
                      locationService.locations.map((loc) {
                        return DropdownMenuItem<String>(
                          value: loc.id,
                          child: Text(loc.location),
                        );
                      }).toList(),
                  onChanged:
                      (value) =>
                          setState(() => _arrivalController.text = value!),
                ),
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Giá'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _distanceController,
                  decoration: InputDecoration(labelText: 'Khoảng cách (km)'),
                ),
                TextField(
                  controller: _totalSeatsController,
                  decoration: InputDecoration(labelText: 'Tổng ghế'),
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  title: Text('Thời gian đi'),
                  subtitle: Text('$_departureTime'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _departureTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_departureTime),
                      );
                      if (time != null) {
                        setState(() {
                          _departureTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  title: Text('Thời gian đến'),
                  subtitle: Text('$_arrivalTime'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _arrivalTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_arrivalTime),
                      );
                      if (time != null) {
                        setState(() {
                          _arrivalTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    final tripService = Provider.of<TripService>(
                      context,
                      listen: false,
                    );
                    final trip = Trip(
                      id: '',
                      vehicle_id: _locationIdController.text,
                      departure_location: _departureController.text,
                      arrival_location: _arrivalController.text,
                      departure_time: _departureTime,
                      arrival_time: _arrivalTime,
                      price: double.parse(_priceController.text),
                      distance: double.parse(_distanceController.text),
                      totalSeats: int.parse(_totalSeatsController.text),
                      createdAt: null,
                    );
                    if (await tripService.createTrip(trip) != null) {
                      Navigator.pushReplacementNamed(context, '/admin/trip');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tạo chuyến đi thất bại')),
                      );
                    }
                  },
                  child: Text('Lưu'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
