/// Wraps geolocator to provide the user's current GPS position.
/// TODO: Handle permission denial gracefully and show settings prompt.
class LocationService {
  /// Returns the user's current [latitude, longitude].
  /// Throws a [LocationServiceException] if permission is denied or
  /// location services are disabled.
  Future<({double latitude, double longitude})> getCurrentPosition() async {
    // TODO: Use geolocator package:
    //   final position = await Geolocator.getCurrentPosition(
    //     desiredAccuracy: LocationAccuracy.high,
    //   );
    throw UnimplementedError('getCurrentPosition not yet implemented');
  }

  /// Streams continuous position updates for the map pin.
  Stream<({double latitude, double longitude})> positionStream() {
    // TODO: Return Geolocator.getPositionStream()
    return const Stream.empty();
  }

  /// Calculates distance in km between two coordinates (Haversine formula).
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    // TODO: Use Geolocator.distanceBetween and convert metres → km
    return 0.0;
  }
}
