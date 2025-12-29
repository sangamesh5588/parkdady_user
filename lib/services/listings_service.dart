import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../domain/entities/parking_slot.dart';
import 'location_service.dart';

/// Model for parking listing from the existing 'listings' table
class Listing {
  final String id;
  final String hostId;
  final String parkingSpaceName;
  final String parkingAddress;
  final double? latitude;
  final double? longitude;
  final String? landmark;
  final String? parkingType;
  final bool is24x7;
  final List<String> amenities;
  final String? openTime;
  final String? closeTime;
  final int? totalBikeSlots;
  final int? totalCarSlots;
  final String? pricingModel;
  final String? entrancePhotoUrl;
  final List<String> parkingPhotos;
  final double? hourlyRateCar;
  final double? dailyRateCar;
  final double? hourlyRateBike;
  final double? dailyRateBike;

  // Discount fields
  final double? hourlyDiscountCar;
  final double? hourlyDiscountBike;
  final double? dailyDiscountCar;
  final double? dailyDiscountBike;
  final double? hourlyDiscountCarPercent;
  final double? hourlyDiscountBikePercent;
  final double? dailyDiscountCarPercent;
  final double? dailyDiscountBikePercent;

  // From parking_active_slots join
  final int? activeCarSlots;
  final int? activeBikeSlots;

  const Listing({
    required this.id,
    required this.hostId,
    required this.parkingSpaceName,
    required this.parkingAddress,
    this.latitude,
    this.longitude,
    this.landmark,
    this.parkingType,
    this.is24x7 = false,
    this.amenities = const [],
    this.openTime,
    this.closeTime,
    this.totalBikeSlots,
    this.totalCarSlots,
    this.pricingModel,
    this.entrancePhotoUrl,
    this.parkingPhotos = const [],
    this.hourlyRateCar,
    this.dailyRateCar,
    this.hourlyRateBike,
    this.dailyRateBike,
    this.hourlyDiscountCar,
    this.hourlyDiscountBike,
    this.dailyDiscountCar,
    this.dailyDiscountBike,
    this.hourlyDiscountCarPercent,
    this.hourlyDiscountBikePercent,
    this.dailyDiscountCarPercent,
    this.dailyDiscountBikePercent,
    this.activeCarSlots,
    this.activeBikeSlots,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    // Parse array from text array (amenities, parking_photos, etc.)
    List<String> parseStringArray(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) {
        // Handle PostgreSQL array format: {item1,item2}
        final cleaned = value.replaceAll('{', '').replaceAll('}', '');
        return cleaned.split(',').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return Listing(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      parkingSpaceName: json['parking_space_name'] as String,
      parkingAddress: json['parking_address'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      landmark: json['landmark'] as String?,
      parkingType: json['parking_type'] as String?,
      is24x7: json['is_24x7'] as bool? ?? false,
      amenities: parseStringArray(json['amenities']),
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      totalBikeSlots: json['total_bike_slots'] as int?,
      totalCarSlots: json['total_car_slots'] as int?,
      pricingModel: json['pricing_model'] as String?,
      entrancePhotoUrl: json['entrance_photo_url'] as String?,
      parkingPhotos: parseStringArray(json['parking_photos']),
      hourlyRateCar: json['hourly_rate_car'] != null ? (json['hourly_rate_car'] as num).toDouble() : null,
      dailyRateCar: json['daily_rate_car'] != null ? (json['daily_rate_car'] as num).toDouble() : null,
      hourlyRateBike: json['hourly_rate_bike'] != null ? (json['hourly_rate_bike'] as num).toDouble() : null,
      dailyRateBike: json['daily_rate_bike'] != null ? (json['daily_rate_bike'] as num).toDouble() : null,
      hourlyDiscountCar: json['hourly_discount_car'] != null ? (json['hourly_discount_car'] as num).toDouble() : null,
      hourlyDiscountBike: json['hourly_discount_bike'] != null ? (json['hourly_discount_bike'] as num).toDouble() : null,
      dailyDiscountCar: json['daily_discount_car'] != null ? (json['daily_discount_car'] as num).toDouble() : null,
      dailyDiscountBike: json['daily_discount_bike'] != null ? (json['daily_discount_bike'] as num).toDouble() : null,
      hourlyDiscountCarPercent: json['hourly_discount_car_percent'] != null ? (json['hourly_discount_car_percent'] as num).toDouble() : null,
      hourlyDiscountBikePercent: json['hourly_discount_bike_percent'] != null ? (json['hourly_discount_bike_percent'] as num).toDouble() : null,
      dailyDiscountCarPercent: json['daily_discount_car_percent'] != null ? (json['daily_discount_car_percent'] as num).toDouble() : null,
      dailyDiscountBikePercent: json['daily_discount_bike_percent'] != null ? (json['daily_discount_bike_percent'] as num).toDouble() : null,
      activeCarSlots: json['active_car_slots'] as int?,
      activeBikeSlots: json['active_bike_slots'] as int?,
    );
  }

  bool get hasAvailability => (activeCarSlots ?? 0) > 0 || (activeBikeSlots ?? 0) > 0;

  int get totalAvailableSlots => (activeCarSlots ?? 0) + (activeBikeSlots ?? 0);

  // Calculate discounted price for car (hourly)
  double getDiscountedHourlyCarPrice() {
    if (hourlyRateCar == null) return 0;
    double price = hourlyRateCar!;

    // Apply flat discount first
    if (hourlyDiscountCar != null && hourlyDiscountCar! > 0) {
      price -= hourlyDiscountCar!;
    }

    // Then apply percentage discount
    if (hourlyDiscountCarPercent != null && hourlyDiscountCarPercent! > 0) {
      price -= (price * hourlyDiscountCarPercent! / 100);
    }

    return price > 0 ? price : 0;
  }

  // Calculate discounted price for bike (hourly)
  double getDiscountedHourlyBikePrice() {
    if (hourlyRateBike == null) return 0;
    double price = hourlyRateBike!;

    // Apply flat discount first
    if (hourlyDiscountBike != null && hourlyDiscountBike! > 0) {
      price -= hourlyDiscountBike!;
    }

    // Then apply percentage discount
    if (hourlyDiscountBikePercent != null && hourlyDiscountBikePercent! > 0) {
      price -= (price * hourlyDiscountBikePercent! / 100);
    }

    return price > 0 ? price : 0;
  }

  // Calculate discounted price for car (daily)
  double getDiscountedDailyCarPrice() {
    if (dailyRateCar == null) return 0;
    double price = dailyRateCar!;

    // Apply flat discount first
    if (dailyDiscountCar != null && dailyDiscountCar! > 0) {
      price -= dailyDiscountCar!;
    }

    // Then apply percentage discount
    if (dailyDiscountCarPercent != null && dailyDiscountCarPercent! > 0) {
      price -= (price * dailyDiscountCarPercent! / 100);
    }

    return price > 0 ? price : 0;
  }

  // Calculate discounted price for bike (daily)
  double getDiscountedDailyBikePrice() {
    if (dailyRateBike == null) return 0;
    double price = dailyRateBike!;

    // Apply flat discount first
    if (dailyDiscountBike != null && dailyDiscountBike! > 0) {
      price -= dailyDiscountBike!;
    }

    // Then apply percentage discount
    if (dailyDiscountBikePercent != null && dailyDiscountBikePercent! > 0) {
      price -= (price * dailyDiscountBikePercent! / 100);
    }

    return price > 0 ? price : 0;
  }

  // Check if any discount is available
  bool get hasDiscount {
    return (hourlyDiscountCar != null && hourlyDiscountCar! > 0) ||
           (hourlyDiscountBike != null && hourlyDiscountBike! > 0) ||
           (dailyDiscountCar != null && dailyDiscountCar! > 0) ||
           (dailyDiscountBike != null && dailyDiscountBike! > 0) ||
           (hourlyDiscountCarPercent != null && hourlyDiscountCarPercent! > 0) ||
           (hourlyDiscountBikePercent != null && hourlyDiscountBikePercent! > 0) ||
           (dailyDiscountCarPercent != null && dailyDiscountCarPercent! > 0) ||
           (dailyDiscountBikePercent != null && dailyDiscountBikePercent! > 0);
  }
}

/// Listing with distance information
class ListingWithDistance {
  final Listing listing;
  final double distanceInMeters;

  const ListingWithDistance({
    required this.listing,
    required this.distanceInMeters,
  });

  String get formattedDistance {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  factory ListingWithDistance.fromJson(Map<String, dynamic> json) {
    return ListingWithDistance(
      listing: Listing.fromJson(json),
      distanceInMeters: json['distance_meters'] != null
        ? (json['distance_meters'] as num).toDouble()
        : 0.0,
    );
  }
}

/// Service for fetching listings from Supabase
class ListingsService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get nearby listings based on user location using the RPC function
  /// This joins with parking_active_slots to show only available listings
  Future<List<ListingWithDistance>> getNearbyListings({
    required LocationData userLocation,
    double radiusInMeters = 5000,
    int limit = 20,
  }) async {
    try {
      print('📍 Fetching listings for location: ${userLocation.latitude}, ${userLocation.longitude}');
      print('📍 Radius: ${radiusInMeters}m, Limit: $limit');

      // Call the Supabase function to get nearby available listings
      final response = await _client.rpc(
        'get_nearby_available_listings',
        params: {
          'user_lat': userLocation.latitude,
          'user_lon': userLocation.longitude,
          'radius_meters': radiusInMeters.toInt(),
          'result_limit': limit,
        },
      );

      print('📦 Response received: ${response != null ? "Yes" : "No"}');

      if (response == null) {
        print('⚠️ Response is null');
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      print('✅ Found ${data.length} listings');

      return data
          .map((json) => ListingWithDistance.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      print('❌ Error fetching nearby listings: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get all available listings (with active slots)
  Future<List<Listing>> getAllListings({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Use RPC function to get listings with availability
      final response = await _client.rpc(
        'get_all_available_listings',
        params: {
          'result_limit': limit,
          'result_offset': offset,
        },
      );

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => Listing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching all listings: $e');
      rethrow;
    }
  }

  /// Get listing by ID
  Future<Listing?> getListingById(String id) async {
    try {
      final response = await _client
          .from('listings')
          .select('*')
          .eq('id', id)
          .single();

      return Listing.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching listing by ID: $e');
      return null;
    }
  }

  /// Get user's own listings
  Future<List<Listing>> getUserListings(String userId) async {
    try {
      final response = await _client
          .from('listings')
          .select('*')
          .eq('host_id', userId)
          .order('parking_space_name', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => Listing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching user listings: $e');
      rethrow;
    }
  }

  /// Search listings by query
  Future<List<Listing>> searchListings({
    required String query,
    int limit = 20,
  }) async {
    try {
      var queryBuilder = _client
          .from('listings')
          .select('*');

      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'parking_space_name.ilike.%$query%,parking_address.ilike.%$query%,landmark.ilike.%$query%'
        );
      }

      final response = await queryBuilder
          .order('parking_space_name', ascending: true)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => Listing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching listings: $e');
      rethrow;
    }
  }

  /// Get available slots for a listing
  Future<List<ParkingSlot>> getAvailableSlots(String listingId) async {
    try {
      final response = await _client
          .from('parking_available_slots')
          .select('*')
          .eq('listing_id', listingId)
          .eq('is_available', true)
          .order('slot_number', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ParkingSlot.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching available slots: $e');
      rethrow;
    }
  }

  /// Create a new listing
  Future<Listing> createListing({
    required String hostId,
    required String parkingSpaceName,
    required String parkingAddress,
    double? latitude,
    double? longitude,
    String? landmark,
  }) async {
    try {
      final response = await _client
          .from('listings')
          .insert({
            'host_id': hostId,
            'parking_space_name': parkingSpaceName,
            'parking_address': parkingAddress,
            'latitude': latitude,
            'longitude': longitude,
            'landmark': landmark,
          })
          .select()
          .single();

      return Listing.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating listing: $e');
      rethrow;
    }
  }

  /// Update an existing listing
  Future<Listing> updateListing({
    required String id,
    String? parkingSpaceName,
    String? parkingAddress,
    double? latitude,
    double? longitude,
    String? landmark,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (parkingSpaceName != null) updateData['parking_space_name'] = parkingSpaceName;
      if (parkingAddress != null) updateData['parking_address'] = parkingAddress;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (landmark != null) updateData['landmark'] = landmark;

      final response = await _client
          .from('listings')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Listing.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating listing: $e');
      rethrow;
    }
  }

  /// Delete a listing
  Future<void> deleteListing(String id) async {
    try {
      await _client
          .from('listings')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting listing: $e');
      rethrow;
    }
  }
}
