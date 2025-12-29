import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../domain/entities/parking_space.dart';
import 'location_service.dart';

/// Nearby Parking Service
/// Handles location-based parking space queries and filtering
class NearbyParkingService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final LocationService _locationService;

  NearbyParkingService(this._locationService);

  /// Get nearby parking spaces based on current location
  Future<List<ParkingSpaceWithDistance>> getNearbyParkingSpaces({
    required LocationData userLocation,
    double radiusInMeters = LocationService.defaultSearchRadius,
    int limit = 20,
    bool onlyAvailableToday = true,
  }) async {
    try {
      // Build the query with location filtering
      final query = _supabase
          .from('parking_spots')
          .select()
          .eq('is_active', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      // Only get spaces with available slots if requested
      if (onlyAvailableToday) {
        query.gt('available_spaces', 0);
      }

      // Execute query first to get all potential spaces
      final response = await query.limit(limit * 2); // Get more for filtering

      final parkingSpaces = (response as List)
          .map((json) => ParkingSpace.fromJson(json))
          .toList();

      // Calculate distances and filter by radius
      final spacesWithDistances = parkingSpaces.map((space) {
        final distance = _locationService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          space.latitude!,
          space.longitude!,
        );

        return ParkingSpaceWithDistance(
          parkingSpace: space,
          distanceInMeters: distance,
        );
      }).where((space) => space.distanceInMeters <= radiusInMeters)
        .toList();

      // Sort by distance and limit results
      spacesWithDistances.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      final limitedResults = spacesWithDistances.take(limit).toList();

      return limitedResults;
    } catch (e) {
      throw Exception('Failed to fetch nearby parking spaces: ${e.toString()}');
    }
  }

  /// Get parking spaces available for today only
  Future<List<ParkingSpaceWithDistance>> getTodaysParkingSpaces({
    required LocationData userLocation,
    double radiusInMeters = LocationService.defaultSearchRadius,
    int limit = 20,
  }) async {
    return getNearbyParkingSpaces(
      userLocation: userLocation,
      radiusInMeters: radiusInMeters,
      limit: limit,
      onlyAvailableToday: true,
    );
  }

  /// Search parking spaces by location and additional filters
  Future<List<ParkingSpaceWithDistance>> searchParkingSpaces({
    required LocationData userLocation,
    String? searchQuery,
    double radiusInMeters = LocationService.defaultSearchRadius,
    List<String>? amenities,
    double? maxPricePerHour,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from('parking_spots')
          .select()
          .eq('is_active', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .gt('available_spaces', 0);

      // Apply search filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,address.ilike.%$searchQuery%,city.ilike.%$searchQuery%');
      }

      if (maxPricePerHour != null) {
        query = query.lte('price_per_hour', maxPricePerHour);
      }

      // Execute query
      final response = await query.limit(limit * 3); // Get more for distance filtering

      final parkingSpaces = (response as List)
          .map((json) => ParkingSpace.fromJson(json))
          .toList();

      // Calculate distances and filter by radius
      final spacesWithDistances = parkingSpaces.map((space) {
        final distance = _locationService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          space.latitude!,
          space.longitude!,
        );

        return ParkingSpaceWithDistance(
          parkingSpace: space,
          distanceInMeters: distance,
        );
      }).where((space) => space.distanceInMeters <= radiusInMeters).toList();

      // Sort by distance and limit results
      spacesWithDistances.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      final limitedResults = spacesWithDistances.take(limit).toList();

      return limitedResults;
    } catch (e) {
      throw Exception('Failed to search parking spaces: ${e.toString()}');
    }
  }

  /// Get parking space details with real-time availability
  Future<ParkingSpaceWithDistance?> getParkingSpaceDetails({
    required String parkingSpaceId,
    required LocationData userLocation,
  }) async {
    try {
      final response = await _supabase
          .from('parking_spots')
          .select()
          .eq('id', parkingSpaceId)
          .eq('is_active', true)
          .single();

      final parkingSpace = ParkingSpace.fromJson(response);

      // Calculate distance
      final distance = _locationService.calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        parkingSpace.latitude!,
        parkingSpace.longitude!,
      );

      return ParkingSpaceWithDistance(
        parkingSpace: parkingSpace,
        distanceInMeters: distance,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get top rated parking spaces nearby
  Future<List<ParkingSpaceWithDistance>> getTopRatedParkingSpaces({
    required LocationData userLocation,
    double radiusInMeters = LocationService.defaultSearchRadius,
    int limit = 10,
  }) async {
    try {
      // First get parking spaces with their average ratings
      final response = await _supabase.rpc('get_parking_spaces_with_ratings').select();

      final parkingSpaces = (response as List)
          .map((json) => ParkingSpace.fromJson(json))
          .where((space) => space.latitude != null && space.longitude != null)
          .toList();

      // Calculate distances and filter
      final spacesWithDistances = parkingSpaces.map((space) {
        final distance = _locationService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          space.latitude!,
          space.longitude!,
        );

        return ParkingSpaceWithDistance(
          parkingSpace: space,
          distanceInMeters: distance,
        );
      }).where((space) => space.distanceInMeters <= radiusInMeters)
        .toList();

      // Sort by available spots as a proxy for popularity
      spacesWithDistances.sort((a, b) {
        final spotsA = a.parkingSpace.availableSpots;
        final spotsB = b.parkingSpace.availableSpots;
        return spotsB.compareTo(spotsA); // Higher availability first
      });

      return spacesWithDistances.take(limit).toList();
    } catch (e) {
      // Fallback to regular nearby search if RPC fails
      return getNearbyParkingSpaces(
        userLocation: userLocation,
        radiusInMeters: radiusInMeters,
        limit: limit,
      );
    }
  }

  /// Check if parking space is available for today
  Future<bool> isParkingSpaceAvailableToday(String parkingSpaceId) async {
    try {
      final response = await _supabase
          .from('parking_spots')
          .select('available_spaces')
          .eq('id', parkingSpaceId)
          .single();

      final availableSpaces = response['available_spaces'] as int;
      return availableSpaces > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get real-time availability stream for nearby parking
  Stream<List<ParkingSpaceWithDistance>> watchNearbyParkingSpaces({
    required LocationData userLocation,
    double radiusInMeters = LocationService.defaultSearchRadius,
    int limit = 20,
  }) {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      try {
        return await getNearbyParkingSpaces(
          userLocation: userLocation,
          radiusInMeters: radiusInMeters,
          limit: limit,
        );
      } catch (e) {
        return [];
      }
    });
  }
}

/// Parking Space with Distance Model
class ParkingSpaceWithDistance {
  final ParkingSpace parkingSpace;
  final double distanceInMeters;

  const ParkingSpaceWithDistance({
    required this.parkingSpace,
    required this.distanceInMeters,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Get distance category
  String get distanceCategory {
    if (distanceInMeters < 500) return 'Very Close';
    if (distanceInMeters < 1000) return 'Close';
    if (distanceInMeters < 2000) return 'Nearby';
    return 'Far';
  }

  /// Check if parking space is available today
  bool get isAvailableToday => parkingSpace.availableSpots > 0;

  @override
  String toString() {
    return 'ParkingSpaceWithDistance(space: ${parkingSpace.name}, distance: $formattedDistance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParkingSpaceWithDistance &&
           other.parkingSpace.id == parkingSpace.id;
  }

  @override
  int get hashCode => parkingSpace.id.hashCode;
}
