import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';

class LocationEditScreen extends StatefulWidget {
  final String id;

  LocationEditScreen({required this.id});

  @override
  _LocationEditScreenState createState() => _LocationEditScreenState();
}

class _LocationEditScreenState extends State<LocationEditScreen> {
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final locationService = Provider.of<LocationService>(context, listen: false);
    final location = locationService.locations.firstWhere((loc) => loc.id == widget.id);
    _locationController.text = location.location;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chỉnh sửa địa điểm')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _locationController, decoration: InputDecoration(labelText: 'Tên địa điểm')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final locationService = Provider.of<LocationService>(context, listen: false);
                if (await locationService.updateLocation(widget.id, _locationController.text) != null) {
                  Navigator.pushReplacementNamed(context, '/location');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật thất bại')));
                }
              },
              child: Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}