import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Fetches the user's current GPS position with clear error messages.
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS is turned off. Please enable Location in your device settings.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in your phone Settings.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  /// Converts GPS coordinates into a readable address (e.g., "Palarivattom, Kochi").
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];

        if (p.street != null && p.street!.trim().isNotEmpty && p.street != p.name) {
          parts.add(p.street!.trim());
        }
        if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) {
          parts.add(p.subLocality!.trim());
        } else if (p.name != null && p.name!.trim().isNotEmpty) {
          parts.add(p.name!.trim());
        }
        if (p.locality != null && p.locality!.trim().isNotEmpty) {
          parts.add(p.locality!.trim());
        }
        if (p.administrativeArea != null && p.administrativeArea!.trim().isNotEmpty) {
          parts.add(p.administrativeArea!.trim());
        }

        // Deduplicate while preserving order
        final uniqueParts = parts.toSet().toList();
        if (uniqueParts.isNotEmpty) {
          return uniqueParts.join(', ');
        }
      }
    } catch (_) {
      // Return null on failure; caller will fall back to lat/lng string
    }
    return null;
  }
}
