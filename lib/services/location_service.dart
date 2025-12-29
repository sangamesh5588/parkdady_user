import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

/// Location Service
/// Handles GPS location tracking with high accuracy and permission management
class LocationService {
  static const double defaultSearchRadius = 5000; // 5km in meters
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const Duration locationTimeout = Duration(seconds: 10);

  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<LocationData> _locationController = StreamController<LocationData>.broadcast();

  LocationData? _lastKnownLocation;

  /// Stream of location updates
  Stream<LocationData> get locationStream => _locationController.stream;

  /// Get last known location
  LocationData? get lastKnownLocation => _lastKnownLocation;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position with high accuracy
  Future<LocationData?> getCurrentLocation() async {
    try {
      debugPrint('🌍 Getting current location...');

      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      debugPrint('📡 Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        throw LocationServiceException('Location services are disabled');
      }

      // Check permission
      var permission = await checkPermission();
      debugPrint('🔐 Location permission: $permission');
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationServiceException('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationServiceException('Location permission permanently denied');
      }

      // Get position with high accuracy
      debugPrint('📍 Fetching GPS position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: locationTimeout,
      );

      debugPrint('✅ Got position: ${position.latitude}, ${position.longitude}');
      final locationData = await _createLocationData(position);
      _lastKnownLocation = locationData;
      _locationController.add(locationData);

      debugPrint('✅ Location data created: ${locationData.displayAddress}');
      return locationData;
    } catch (e) {
      debugPrint('❌ Location error: $e');
      if (e is LocationServiceException) {
        rethrow;
      }
      throw LocationServiceException('Failed to get location: ${e.toString()}');
    }
  }

  /// Start location tracking
  Future<void> startLocationTracking() async {
    try {
      // Check permissions first
      final permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw LocationServiceException('Location permission not granted');
      }

      // Stop existing tracking if any
      await stopLocationTracking();

      // Start tracking with high accuracy
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50, // Update every 50 meters
          timeLimit: locationTimeout,
        ),
      ).listen(
        (Position position) async {
          try {
            final locationData = await _createLocationData(position);
            _lastKnownLocation = locationData;
            _locationController.add(locationData);
          } catch (e) {
            debugPrint('Error processing location update: $e');
          }
        },
        onError: (error) {
          debugPrint('Location tracking error: $error');
          _locationController.addError(LocationServiceException('Location tracking failed: $error'));
        },
      );
    } catch (e) {
      throw LocationServiceException('Failed to start location tracking: ${e.toString()}');
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Build full address with street, area, city
        final addressParts = <String>[];

        // Add street or name if available
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        } else if (place.name != null && place.name!.isNotEmpty && place.name != place.locality) {
          addressParts.add(place.name!);
        }

        // Add sublocality (area/neighborhood)
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }

        // Add locality (city)
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }

        // Add administrative area (state) if different from city
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty &&
            place.administrativeArea != place.locality) {
          addressParts.add(place.administrativeArea!);
        }

        return addressParts.isNotEmpty ? addressParts.join(', ') : null;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance; // Distance in meters
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Create LocationData from Position
  Future<LocationData> _createLocationData(Position position) async {
    final address = await getAddressFromCoordinates(position.latitude, position.longitude);

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      heading: position.heading,
      timestamp: position.timestamp ?? DateTime.now(),
      address: address,
    );
  }

  /// Dispose of resources
  void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
}

/// Location Data Model
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final double heading;
  final DateTime timestamp;
  final String? address;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.speedAccuracy,
    required this.heading,
    required this.timestamp,
    this.address,
  });

  /// Create from JSON (for caching)
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      accuracy: json['accuracy'] as double? ?? 0.0,
      altitude: json['altitude'] as double? ?? 0.0,
      speed: json['speed'] as double? ?? 0.0,
      speedAccuracy: json['speedAccuracy'] as double? ?? 0.0,
      heading: json['heading'] as double? ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String?,
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'speedAccuracy': speedAccuracy,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
    };
  }

  /// Get formatted address or coordinates fallback
  String get displayAddress {
    if (address != null && address!.isNotEmpty) {
      return address!;
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Check if location is recent (within last 5 minutes)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inMinutes < 5;
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationData &&
           other.latitude == latitude &&
           other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Location Service Exception
class LocationServiceException implements Exception {
  final String message;

  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
