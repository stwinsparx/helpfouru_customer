import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return '${position.latitude},${position.longitude}';
    } catch (_) {
      // Ignored — coordinates are best-effort.
      return null;
    }
  }
}
