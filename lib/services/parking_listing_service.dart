import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../domain/entities/parking_listing.dart';
import '../domain/entities/parking_slot.dart';
import 'location_service.dart';

/// Service for fetching parking listings and slots from Supabase
class ParkingListingService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get nearby parking listings based on user location
  Future<List<ParkingListingWithDistance>> getNearbyListings({
    required LocationData userLocation,
    double radiusInMeters = 5000,
    int limit = 20,
  }) async {
    try {
      // Call the Supabase function to get nearby listings
      final response = await _client.rpc(
        'get_nearby_parking_listings',
        params: {
          'user_lat': userLocation.latitude,
          'user_lon': userLocation.longitude,
          'radius_meters': radiusInMeters.toInt(),
          'result_limit': limit,
        },
      );

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ParkingListingWithDistance.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching nearby listings: $e');
      rethrow;
    }
  }

  /// Get all published parking listings
  Future<List<ParkingListing>> getAllListings({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('user_parking_listing')
          .select('*')
          .eq('is_active', true)
          .eq('is_published', true)
          .gt('available_slots', 0)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ParkingListing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching all listings: $e');
      rethrow;
    }
  }

  /// Get parking listing by ID
  Future<ParkingListing?> getListingById(String id) async {
    try {
      final response = await _client
          .from('user_parking_listing')
          .select('*')
          .eq('id', id)
          .single();

      return ParkingListing.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching listing by ID: $e');
      return null;
    }
  }

  /// Get user's own parking listings
  Future<List<ParkingListing>> getUserListings(String userId) async {
    try {
      final response = await _client
          .from('user_parking_listing')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ParkingListing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching user listings: $e');
      rethrow;
    }
  }

  /// Search parking listings by query
  Future<List<ParkingListing>> searchListings({
    required String query,
    String? city,
    String? state,
    double? maxPrice,
    List<String>? amenities,
    int limit = 20,
  }) async {
    try {
      var queryBuilder = _client
          .from('user_parking_listing')
          .select('*')
          .eq('is_active', true)
          .eq('is_published', true)
          .gt('available_slots', 0);

      // Apply filters
      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.or('title.ilike.%$query%,address.ilike.%$query%,city.ilike.%$query%');
      }

      if (city != null && city.isNotEmpty) {
        queryBuilder = queryBuilder.eq('city', city);
      }

      if (state != null && state.isNotEmpty) {
        queryBuilder = queryBuilder.eq('state', state);
      }

      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('price_per_hour', maxPrice);
      }

      // Note: For amenities filtering, you'd need to use contains
      // This requires the amenities column to be properly set up as JSONB
      if (amenities != null && amenities.isNotEmpty) {
        for (final amenity in amenities) {
          queryBuilder = queryBuilder.contains('amenities', [amenity]);
        }
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ParkingListing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching listings: $e');
      rethrow;
    }
  }

  /// Get available slots for a parking listing
  Future<List<ParkingSlot>> getAvailableSlots(String parkingSpaceId) async {
    try {
      final response = await _client
          .from('parking_available_slots')
          .select('*')
          .eq('parking_space_id', parkingSpaceId)
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

  /// Create a new parking listing
  Future<ParkingListing> createListing(ParkingListing listing) async {
    try {
      final response = await _client
          .from('user_parking_listing')
          .insert(listing.toJson())
          .select()
          .single();

      return ParkingListing.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating listing: $e');
      rethrow;
    }
  }

  /// Update an existing parking listing
  Future<ParkingListing> updateListing(String id, ParkingListing listing) async {
    try {
      final response = await _client
          .from('user_parking_listing')
          .update(listing.toJson())
          .eq('id', id)
          .select()
          .single();

      return ParkingListing.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating listing: $e');
      rethrow;
    }
  }

  /// Delete a parking listing
  Future<void> deleteListing(String id) async {
    try {
      await _client
          .from('user_parking_listing')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting listing: $e');
      rethrow;
    }
  }

  /// Toggle listing publish status
  Future<void> togglePublishStatus(String id, bool isPublished) async {
    try {
      await _client
          .from('user_parking_listing')
          .update({'is_published': isPublished})
          .eq('id', id);
    } catch (e) {
      print('Error toggling publish status: $e');
      rethrow;
    }
  }

  /// Update available slots count
  Future<void> updateAvailableSlots(String id, int availableSlots) async {
    try {
      await _client
          .from('user_parking_listing')
          .update({'available_slots': availableSlots})
          .eq('id', id);
    } catch (e) {
      print('Error updating available slots: $e');
      rethrow;
    }
  }
}
