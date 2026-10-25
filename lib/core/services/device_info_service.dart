import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/picked_location.dart';

/// Why a [DeviceInfoService.currentLocationStatus] call couldn't produce a
/// usable fix — lets callers distinguish "ask for permission" from "turn on
/// GPS" from "got nothing, try again" UI, which a plain `null` coordinate
/// string can't.
enum LocationStatus {
  /// A fresh position was obtained — coordinates are available.
  available,

  /// Location services (GPS) are off at the OS level.
  serviceDisabled,

  /// Permission was denied (but can be asked for again).
  permissionDenied,

  /// Permission was permanently denied — only Settings can fix this.
  permissionDeniedForever,

  /// Something else went wrong (e.g. the position request itself failed).
  unavailable,
}

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

  /// Returns "lat,lng" for [addressLine] (forward-geocoded), or — when
  /// [addressLine] is `null`/blank, or geocoding fails/finds nothing — falls
  /// back to the device's live GPS position via [loginCoordinates]. Used to
  /// send the coordinates of whichever address the customer explicitly
  /// selected on the home screen (see `AppState.selectedAddress`) rather
  /// than always sending wherever the phone currently is, which may not be
  /// the same place if they picked a saved address like "Office".
  static Future<String?> orderCoordinates({String? addressLine}) async {
    if (addressLine == null || addressLine.trim().isEmpty) {
      return loginCoordinates();
    }
    try {
      final locations = await Geocoding().locationFromAddress(addressLine);
      if (locations.isEmpty) return await loginCoordinates();
      final location = locations.first;
      return '${location.latitude},${location.longitude}';
    } catch (_) {
      // Geocoding failed (no network, address not resolvable, etc.) — fall
      // back to live GPS rather than sending no coordinates at all.
      return await loginCoordinates();
    }
  }

  /// Reverse-geocodes [latitude]/[longitude] (a dropped pin or dragged map
  /// center on [LocationMapPickerScreen]) into a [PickedLocation] — `null`
  /// if geocoding fails or finds nothing for that point.
  static Future<PickedLocation?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final line = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ].where((p) => p != null && p.isNotEmpty).join(', ');
      return PickedLocation(
        latitude: latitude,
        longitude: longitude,
        formattedAddress: line,
        locality: place.locality,
        administrativeArea: place.administrativeArea,
        postalCode: place.postalCode,
      );
    } catch (_) {
      return null;
    }
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

  /// Like [loginCoordinates], but reports *why* a fix couldn't be obtained
  /// instead of silently returning null — needed to show the right
  /// "turn on location" / "open settings" UI rather than a generic empty
  /// state. Requests permission (prompting the OS dialog) if not yet
  /// decided, same as [_currentPosition].
  static Future<(LocationStatus, String?)> currentLocationStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return (LocationStatus.serviceDisabled, null);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return (LocationStatus.permissionDenied, null);
      }
      if (permission == LocationPermission.deniedForever) {
        return (LocationStatus.permissionDeniedForever, null);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return (
        LocationStatus.available,
        '${position.latitude},${position.longitude}',
      );
    } catch (_) {
      return (LocationStatus.unavailable, null);
    }
  }
}
