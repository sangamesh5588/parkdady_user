import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'location_service.dart';

class SearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String address;

  const SearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class SearchService {
  /// Search for a location by name and return coordinates
  Future<SearchResult?> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      return null;
    }

    try {
      // Use geocoding to convert place name to coordinates
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        debugPrint('No locations found for query: $query');
        return null;
      }

      final location = locations.first;

      // Reverse geocode to get formatted address
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      String formattedAddress = query;
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        formattedAddress = _formatAddress(placemark);
      }

      return SearchResult(
        displayName: query,
        latitude: location.latitude,
        longitude: location.longitude,
        address: formattedAddress,
      );
    } catch (e) {
      debugPrint('Error searching for location "$query": $e');
      return null;
    }
  }

  /// Get location suggestions based on partial query
  /// Note: This is a basic implementation. For production, consider using
  /// Google Places API for better autocomplete suggestions
  Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty || query.length < 3) {
      return [];
    }

    // Basic implementation - in production, use Google Places Autocomplete API
    // For now, return empty list as this would require API integration
    return [];
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    } else if (placemark.subAdministrativeArea != null &&
               placemark.subAdministrativeArea!.isNotEmpty) {
      parts.add(placemark.subAdministrativeArea!);
    }

    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }

    return parts.join(', ');
  }

  /// Convert SearchResult to LocationData for use with parking services
  LocationData toLocationData(SearchResult result) {
    return LocationData(
      latitude: result.latitude,
      longitude: result.longitude,
      accuracy: 0.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: result.address,
    );
  }
}
