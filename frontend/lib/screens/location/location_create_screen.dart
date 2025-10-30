import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';

class LocationCreateScreen extends StatefulWidget {
  @override
  _LocationCreateScreenState createState() => _LocationCreateScreenState();
}

class _LocationCreateScreenState extends State<LocationCreateScreen> {
  final _locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tạo địa điểm')),
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
                if (await locationService.createLocation(_locationController.text) != null) {
                  Navigator.pushReplacementNamed(context, '/location');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tạo địa điểm thất bại')));
                }
              },
              child: Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}