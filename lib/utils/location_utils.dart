import 'package:geolocator/geolocator.dart';

Future<Position?> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled
    return null;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever
    return null;
  }

  // When permissions are granted
  // ignore: deprecated_member_use
  return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
}
