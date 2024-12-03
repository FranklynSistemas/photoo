import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/location_service.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  Future<void> fetchLocation() async {
    try {
      print('getting location');
      _currentPosition = await LocationService().determinePosition();
      print('Location: $_currentPosition');
      notifyListeners();
    } catch (e) {
      print('Failed to get location: $e');
    }
  }
}