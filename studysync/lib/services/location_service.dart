import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> requestPermission() async {
    debugPrint('[Location] Checking permission...');
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('[Location] Current permission: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('[Location] Requesting permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('[Location] Permission after request: $permission');
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[Location] Permission permanently denied.');
      return false;
    }

    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    debugPrint('[Location] Permission granted: $granted');
    return granted;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('[Location] Checking if location service is enabled...');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[Location] Service enabled: $serviceEnabled');
      if (!serviceEnabled) return null;

      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      // Fast first fix with lowest accuracy (cell tower / WiFi).
      debugPrint('[Location] Requesting lowest-accuracy position...');
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.lowest,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('GPS timeout (lowest)'),
        );
        debugPrint(
            '[Location] Got position: ${position.latitude}, ${position.longitude}');
      } on TimeoutException {
        debugPrint('[Location] Lowest-accuracy timed out, trying low...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('GPS timeout (low)'),
        );
        debugPrint(
            '[Location] Got low-accuracy position: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      debugPrint('[Location] Error getting position: $e');
      return null;
    }
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000;
  }
}
