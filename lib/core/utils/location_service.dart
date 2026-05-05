import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps geolocator + permission_handler to provide the user's current location.
/// Returns null if permission is denied or location services are disabled.
class LocationService {
  /// Requests location permission and returns the current position.
  /// Returns null if permission denied or location unavailable.
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[Location] Location services are disabled');
        return null;
      }

      // Request permission
      final status = await Permission.location.request();
      if (!status.isGranted) {
        debugPrint('[Location] Permission denied: $status');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      debugPrint(
          '[Location] Got position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('[Location] Error getting position: $e');
      return null;
    }
  }
}
