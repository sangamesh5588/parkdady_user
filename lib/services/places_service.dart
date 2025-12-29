import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

/// Places Service for Google Places API integration
class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const Duration _timeout = Duration(seconds: 10);

  /// Get place autocomplete suggestions
  Future<List<PlaceSuggestion>> getPlaceSuggestions(String input) async {
    if (input.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=${AppConfig.googleMapsApiKey}'
        '&components=country:in' // Restrict to India for better results
      );

      print('🔍 Fetching place suggestions for: $input');
      print('📍 API URL: ${url.toString().replaceAll(AppConfig.googleMapsApiKey, 'API_KEY_HIDDEN')}');

      final response = await http.get(url).timeout(_timeout);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📝 API Response status: ${data['status']}');

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          print('✅ Found ${predictions.length} suggestions');
          return predictions.map((prediction) => PlaceSuggestion.fromJson(prediction)).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          print('⚠️ No results found');
          return [];
        } else {
          print('❌ API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');
      throw Exception('Failed to get place suggestions: $e');
    }
  }

  /// Get place details including coordinates
  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json'
        '?place_id=$placeId'
        '&key=${AppConfig.googleMapsApiKey}'
        '&fields=formatted_address,geometry,name'
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get place details: $e');
    }
  }

  /// Search for places near a location
  Future<List<PlaceSuggestion>> searchNearbyPlaces(
    double latitude,
    double longitude,
    String keyword,
    {int radius = 5000} // 5km radius
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json'
        '?location=$latitude,$longitude'
        '&radius=$radius'
        '&keyword=${Uri.encodeComponent(keyword)}'
        '&key=${AppConfig.googleMapsApiKey}'
        '&type=establishment'
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results.map((result) => PlaceSuggestion.fromNearbySearch(result)).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search nearby places: $e');
    }
  }
}

/// Place Suggestion Model
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final List<String> types;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.types,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    final terms = json['terms'] as List? ?? [];

    String mainText = structuredFormatting['main_text'] ?? '';
    String secondaryText = structuredFormatting['secondary_text'] ?? '';

    // Fallback to description if structured formatting is not available
    if (mainText.isEmpty && secondaryText.isEmpty) {
      final description = json['description'] as String? ?? '';
      final parts = description.split(', ');
      if (parts.length >= 2) {
        mainText = parts[0];
        secondaryText = parts.sublist(1).join(', ');
      } else {
        mainText = description;
      }
    }

    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: mainText,
      secondaryText: secondaryText,
      types: List<String>.from(json['types'] ?? []),
    );
  }

  factory PlaceSuggestion.fromNearbySearch(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['name'] ?? '',
      mainText: json['name'] ?? '',
      secondaryText: json['vicinity'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }

  @override
  String toString() => description;
}

/// Place Details Model
class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};

    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      latitude: (location['lat'] ?? 0.0).toDouble(),
      longitude: (location['lng'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() => '$name: $latitude, $longitude';
}
