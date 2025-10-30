import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/seat.dart';
import '../../services/seat_service.dart';
import '../../services/trip_service.dart';

class SeatEditScreen extends StatefulWidget {
  final String id;

  SeatEditScreen({required this.id});

  @override
  _SeatEditScreenState createState() => _SeatEditScreenState();
}

class _SeatEditScreenState extends State<SeatEditScreen> {
  final _tripIdController = TextEditingController();
  final _seatNumberController = TextEditingController();
  String _statusSeat = 'AVAILABLE';

  @override
  void initState() {
    super.initState();
    final seatService = Provider.of<SeatService>(context, listen: false);
    final seat = seatService.seats.firstWhere((s) => s.id == widget.id);
    _tripIdController.text = seat.tripId;
    _seatNumberController.text = seat.seatNumber.toString();
    _statusSeat = seat.statusSeat; // Sử dụng statusSeat
    Provider.of<TripService>(context, listen: false).fetchTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chỉnh sửa ghế')),
      body: Consumer<TripService>(
        builder: (context, tripService, _) {
          if (tripService.isLoading) return Center(child: CircularProgressIndicator());
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<String>(
                  hint: Text('Chọn chuyến đi'),
                  value: _tripIdController.text.isNotEmpty ? _tripIdController.text : null,
                  items: tripService.trips.map((trip) {
                    return DropdownMenuItem<String>(value: trip.id, child: Text('${trip.departure_location} - ${trip.arrival_location}'));
                  }).toList(),
                  onChanged: (value) => setState(() => _tripIdController.text = value!),
                ),
                TextField(controller: _seatNumberController, decoration: InputDecoration(labelText: 'Số ghế'), keyboardType: TextInputType.number),
                DropdownButton<String>(
                  hint: Text('Trạng thái ghế'),
                  value: _statusSeat,
                  items: ['AVAILABLE', 'BOOKED', 'UNAVAILABLE'].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _statusSeat = value!),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final seatService = Provider.of<SeatService>(context, listen: false);
                    final seat = Seat(
                      id: widget.id,
                      tripId: _tripIdController.text,
                      seatNumber: int.parse(_seatNumberController.text),
                      statusSeat: _statusSeat,
                      createdAt: null,
                      updatedAt: null,
                    );
                    if (await seatService.updateSeat(widget.id, seat) != null) {
                      Navigator.pushReplacementNamed(context, '/seat');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật thất bại')));
                    }
                  },
                  child: Text('Cập nhật'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}