import 'package:dio/dio.dart';
import '../../models/picked_location.dart';

/// A single Google Places Autocomplete suggestion.
class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});

  final String placeId;

  /// Full suggestion text, e.g. "Hiran Magri, Udaipur, Rajasthan, India".
  final String description;
}

/// Thin wrapper around the Google Places Autocomplete + Place Details REST
/// endpoints — used only by [LocationMapPickerScreen]'s search box. Separate
/// from [ApiService] since that Dio instance is bound to this app's own
/// backend (with its own auth interceptor); this one talks directly to
/// Google and needs the Maps API key instead.
class PlacesService {
  static const _apiKey = 'AIzaSyBvv9Nz4ajBN5Fe2puIVbHZKQtQczzu8kk';

  final Dio _dio = Dio();

  /// Text-search suggestions for [query] — empty list on any failure (no
  /// network, invalid key, no matches) rather than throwing, since this is a
  /// type-ahead and a failed lookup should just show no suggestions.
  Future<List<PlaceSuggestion>> autocomplete(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {'input': query, 'key': _apiKey},
      );
      if (response.data['status'] != 'OK') return [];
      final predictions = response.data['predictions'] as List<dynamic>;
      return predictions
          .map(
            (p) => PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Resolves [placeId] (from [autocomplete]) to its coordinates + address
  /// components — `null` on any failure.
  Future<PickedLocation?> placeDetails(String placeId) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'formatted_address,geometry,address_component',
          'key': _apiKey,
        },
      );
      if (response.data['status'] != 'OK') return null;
      final result = response.data['result'] as Map<String, dynamic>;
      final location = result['geometry']['location'] as Map<String, dynamic>;
      final components = (result['address_components'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      String? componentOf(String type) {
        for (final c in components) {
          if ((c['types'] as List<dynamic>).contains(type)) {
            return c['long_name'] as String?;
          }
        }
        return null;
      }

      return PickedLocation(
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
        formattedAddress: result['formatted_address'] as String? ?? '',
        locality: componentOf('locality'),
        administrativeArea: componentOf('administrative_area_level_1'),
        postalCode: componentOf('postal_code'),
      );
    } catch (_) {
      return null;
    }
  }
}
