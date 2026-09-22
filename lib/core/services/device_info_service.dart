import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Best-effort device name and current coordinates for login telemetry.
/// Both fall back to null when unavailable rather than blocking login.
class DeviceInfoService {
  static Future<String?> deviceName() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return '${info.manufacturer} ${info.model}';
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.utsname.machine;
      }
    } catch (_) {
      // Ignored — device name is best-effort.
    }
    return null;
  }

  /// Returns "lat,lng", or null if location is unavailable/denied.
  static Future<String?> loginCoordinates() async {
    final position = await _currentPosition();
    if (position == null) return null;
    return '${position.latitude},${position.longitude}';
  }

  /// Returns a short, human-readable "locality, administrative area" string
  /// (e.g. "Udaipur, Rajasthan") for the device's current position, or null
  /// if location/geocoding is unavailable, denied, or fails.
  static Future<String?> currentAddress() async {
    try {
      final position = await _currentPosition();
      if (position == null) return null;

      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = [
        place.locality,
        place.administrativeArea,
      ].where((p) => p != null && p.isNotEmpty).toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      // Ignored — address is best-effort.
      return null;
    }
  }

  static Future<Position?> _currentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      // Ignored — position is best-effort.
      return null;
    }
  }
}
