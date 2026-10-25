/// A location resolved from [LocationMapPickerScreen] — either by dropping
/// a pin, dragging the map, or picking a Places search result. Carries both
/// the exact coordinates and a best-effort reverse-geocoded breakdown, since
/// callers need the coordinates for `coordinates`/`customer_coordinates` API
/// fields and the text for address/city/state form fields.
class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.locality,
    this.administrativeArea,
    this.postalCode,
  });

  final double latitude;
  final double longitude;

  /// Full human-readable address line, suitable for an "Address" text field.
  final String formattedAddress;

  /// City-equivalent, e.g. "Udaipur" — `null` if reverse geocoding didn't
  /// return one.
  final String? locality;

  /// State-equivalent, e.g. "Rajasthan" — `null` if reverse geocoding
  /// didn't return one.
  final String? administrativeArea;

  final String? postalCode;

  /// "lat,lng" — exactly the string format every coordinates-carrying API
  /// field in this app expects (see `DeviceInfoService`).
  String get coordinates => '$latitude,$longitude';
}
