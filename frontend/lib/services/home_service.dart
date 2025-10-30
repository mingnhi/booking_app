import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../models/location.dart';
import '../services/trip_service.dart';
import '../services/location_service.dart';
import 'package:flutter/material.dart';

class HomeService extends ChangeNotifier {
  bool isLoading = false;
  List<Trip> featuredTrips = [];
  List<Location> locations = [];
  String? errorMessage;

  Future<void> fetchHomeData(BuildContext context) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final tripService = Provider.of<TripService>(context, listen: false);
      final locationService = Provider.of<LocationService>(context, listen: false);

      // Gọi fetchTrips và fetchLocations với allowUnauthenticated = true
      await tripService.fetchTrips(allowUnauthenticated: true);
      featuredTrips = tripService.trips.take(5).toList();

      await locationService.fetchLocations(allowUnauthenticated: true);
      locations = locationService.locations;
    } catch (e) {
      print('Error fetching home data: $e');
      errorMessage = 'Không thể tải dữ liệu. Vui lòng thử lại sau.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}