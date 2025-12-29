import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/parking_space.dart';
import '../../core/supabase_config.dart';
import '../../services/location_service.dart';
import '../../services/nearby_parking_service.dart';
import '../../services/listings_service.dart';
import '../../services/search_service.dart';

// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Nearby parking service provider
final nearbyParkingServiceProvider = Provider<NearbyParkingService>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return NearbyParkingService(locationService);
});

// Listings service provider (for the existing 'listings' table)
final listingsServiceProvider = Provider<ListingsService>((ref) {
  return ListingsService();
});

// Search service provider
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Searched location provider (stores location from search)
final searchedLocationProvider = StateProvider<LocationData?>((ref) => null);

// Current location provider
final currentLocationProvider = StateNotifierProvider<LocationNotifier, AsyncValue<LocationData?>>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});

// Provider for nearby parking spaces based on current location
final nearbyParkingSpacesProvider = StateNotifierProvider<NearbyParkingNotifier, AsyncValue<List<ParkingSpaceWithDistance>>>((ref) {
  final nearbyService = ref.watch(nearbyParkingServiceProvider);
  final locationAsync = ref.watch(currentLocationProvider);

  return NearbyParkingNotifier(nearbyService, locationAsync);
});

// Legacy provider for parking spaces (keeping for compatibility)
final parkingSpacesProvider = StateNotifierProvider<ParkingNotifier, AsyncValue<List<ParkingSpace>>>((ref) {
  return ParkingNotifier();
});

class ParkingNotifier extends StateNotifier<AsyncValue<List<ParkingSpace>>> {
  ParkingNotifier() : super(const AsyncValue.loading()) {
    // Optionally load initial data here
  }

  Future<void> loadParkingSpaces() async {
    state = const AsyncValue.loading();

    try {
      final response = await SupabaseConfig.client
          .from('parking_spots')
          .select('*')
          .order('created_at', ascending: false);

      final parkingSpaces = response.map((json) => ParkingSpace.fromJson(json)).toList();
      state = AsyncValue.data(parkingSpaces);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshParkingSpaces() async {
    await loadParkingSpaces();
  }

  Future<void> createParkingSpace(ParkingSpace parkingSpace) async {
    try {
      final response = await SupabaseConfig.client
          .from('parking_spots')
          .insert(parkingSpace.toJson())
          .select()
          .single();

      final newParkingSpace = ParkingSpace.fromJson(response);

      // Update the state with the new parking space
      state = state.maybeWhen(
        data: (parkingSpaces) => AsyncValue.data([newParkingSpace, ...parkingSpaces]),
        orElse: () => AsyncValue.data([newParkingSpace]),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateParkingSpace(String id, ParkingSpace updatedSpace) async {
    try {
      await SupabaseConfig.client
          .from('parking_spots')
          .update(updatedSpace.toJson())
          .eq('id', id);

      // Update local state
      state = state.maybeWhen(
        data: (parkingSpaces) => AsyncValue.data(
          parkingSpaces.map((space) => space.id == id ? updatedSpace : space).toList(),
        ),
        orElse: () => state,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteParkingSpace(String id) async {
    try {
      await SupabaseConfig.client
          .from('parking_spots')
          .delete()
          .eq('id', id);

      // Update local state
      state = state.maybeWhen(
        data: (parkingSpaces) => AsyncValue.data(
          parkingSpaces.where((space) => space.id != id).toList(),
        ),
        orElse: () => state,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }


}

/// Location Notifier for managing current location state
class LocationNotifier extends StateNotifier<AsyncValue<LocationData?>> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const AsyncValue.data(null));

  Future<void> getCurrentLocation() async {
    state = const AsyncValue.loading();
    try {
      final location = await _locationService.getCurrentLocation();
      state = AsyncValue.data(location);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> requestPermission() async {
    try {
      await _locationService.requestPermission();
      await getCurrentLocation();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void clearLocation() {
    state = const AsyncValue.data(null);
  }
}

/// Nearby Parking Notifier for location-based parking queries
class NearbyParkingNotifier extends StateNotifier<AsyncValue<List<ParkingSpaceWithDistance>>> {
  final NearbyParkingService _nearbyService;
  final AsyncValue<LocationData?> _locationAsync;

  NearbyParkingNotifier(this._nearbyService, this._locationAsync) : super(const AsyncValue.data([])) {
    // Load nearby parking when location is available
    _locationAsync.whenData((location) {
      if (location != null) {
        loadNearbyParkingSpaces(location);
      }
    });
  }

  Future<void> loadNearbyParkingSpaces(LocationData location, {
    double radiusInMeters = LocationService.defaultSearchRadius,
    int limit = 20,
  }) async {
    state = const AsyncValue.loading();
    try {
      final spaces = await _nearbyService.getTodaysParkingSpaces(
        userLocation: location,
        radiusInMeters: radiusInMeters,
        limit: limit,
      );
      state = AsyncValue.data(spaces);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshNearbyParkingSpaces(LocationData location) async {
    await loadNearbyParkingSpaces(location);
  }

  Future<void> searchNearbyParkingSpaces(
    LocationData location,
    String searchQuery, {
    double radiusInMeters = LocationService.defaultSearchRadius,
    int limit = 20,
  }) async {
    if (searchQuery.isEmpty) {
      await loadNearbyParkingSpaces(location, radiusInMeters: radiusInMeters, limit: limit);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final spaces = await _nearbyService.searchParkingSpaces(
        userLocation: location,
        searchQuery: searchQuery,
        radiusInMeters: radiusInMeters,
        limit: limit,
      );
      state = AsyncValue.data(spaces);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Home Page Search Filters Model
class HomeSearchFilters {
  final String location;
  final DateTime date;
  final TimeOfDay startTime;
  final Duration duration;
  final List<String> selectedFilters;
  final double? maxPrice;

  HomeSearchFilters({
    this.location = '',
    DateTime? date,
    TimeOfDay? startTime,
    Duration? duration,
    this.selectedFilters = const [],
    this.maxPrice,
  }) :
    date = date ?? DateTime.now(),
    startTime = startTime ?? TimeOfDay.now(),
    duration = duration ?? const Duration(hours: 2);

  factory HomeSearchFilters.initial() {
    return HomeSearchFilters(
      location: '',
      date: DateTime.now(),
      startTime: TimeOfDay.now(),
      duration: const Duration(hours: 2),
      selectedFilters: const [],
      maxPrice: null,
    );
  }

  HomeSearchFilters copyWith({
    String? location,
    DateTime? date,
    TimeOfDay? startTime,
    Duration? duration,
    List<String>? selectedFilters,
    double? maxPrice,
  }) {
    return HomeSearchFilters(
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  // Get combined start DateTime
  DateTime get startDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
  }

  // Get combined end DateTime
  DateTime get endDateTime {
    return startDateTime.add(duration);
  }

  @override
  String toString() {
    return 'HomeSearchFilters(location: $location, date: $date, time: $startTime, duration: $duration, filters: $selectedFilters)';
  }
}

/// Parking Space Card Model for Home Page Display
class ParkingSpaceCard {
  final String id;
  final String name;
  final String address;
  final double pricePerHour;
  final int availableSpots;
  final double distanceInMeters;
  final List<String> images;
  final List<String> features;
  final List<String> allAmenities; // All amenities from database
  final double? averageRating;
  final int? reviewCount;
  final bool isCovered;
  final bool hasEvCharging;
  final bool is24x7;

  // Location data
  final double? latitude;
  final double? longitude;

  // Pricing data for different vehicle types
  final double? hourlyRateCar;
  final double? dailyRateCar;
  final double? hourlyRateBike;
  final double? dailyRateBike;

  // Discount data
  final double? hourlyDiscountCar;
  final double? hourlyDiscountBike;
  final double? dailyDiscountCar;
  final double? dailyDiscountBike;
  final double? hourlyDiscountCarPercent;
  final double? hourlyDiscountBikePercent;
  final double? dailyDiscountCarPercent;
  final double? dailyDiscountBikePercent;

  const ParkingSpaceCard({
    required this.id,
    required this.name,
    required this.address,
    required this.pricePerHour,
    required this.availableSpots,
    required this.distanceInMeters,
    required this.images,
    required this.features,
    this.allAmenities = const [],
    this.averageRating,
    this.reviewCount,
    this.isCovered = false,
    this.hasEvCharging = false,
    this.is24x7 = false,
    this.latitude,
    this.longitude,
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
  });

  factory ParkingSpaceCard.fromParkingSpaceWithDistance(ParkingSpaceWithDistance space) {
    final features = _extractFeatures(space.parkingSpace);

    return ParkingSpaceCard(
      id: space.parkingSpace.id,
      name: space.parkingSpace.name,
      address: space.parkingSpace.address,
      pricePerHour: space.parkingSpace.pricePerHour,
      availableSpots: space.parkingSpace.availableSpots,
      distanceInMeters: space.distanceInMeters,
      images: space.parkingSpace.images,
      features: features,
      allAmenities: features, // Use extracted features as amenities
      averageRating: 4.5, // TODO: Get from reviews
      reviewCount: 0, // TODO: Get from reviews
      isCovered: space.parkingSpace.description.toLowerCase().contains('covered'),
      hasEvCharging: space.parkingSpace.description.toLowerCase().contains('ev') ||
                    space.parkingSpace.description.toLowerCase().contains('electric'),
      is24x7: space.parkingSpace.description.toLowerCase().contains('24') ||
             space.parkingSpace.description.toLowerCase().contains('24/7'),
    );
  }

  factory ParkingSpaceCard.fromListing(ListingWithDistance listingWithDistance) {
    final listing = listingWithDistance.listing;

    // Extract top 3 features for card display
    final features = <String>[];
    for (final amenity in listing.amenities) {
      final lowerAmenity = amenity.toLowerCase();
      if (lowerAmenity.contains('covered') && !features.contains('Covered')) {
        features.add('Covered');
      } else if ((lowerAmenity.contains('cctv') || lowerAmenity.contains('security')) && !features.contains('CCTV')) {
        features.add('CCTV');
      } else if (lowerAmenity.contains('ev') && !features.contains('EV')) {
        features.add('EV');
      } else if (lowerAmenity.contains('valet') && !features.contains('Valet')) {
        features.add('Valet');
      }
      if (features.length >= 3) break;
    }

    // Add landmark as a feature if available
    if (features.length < 3 && listing.landmark != null && listing.landmark!.isNotEmpty) {
      features.add(listing.landmark!);
    }

    // Determine price (prefer hourly rate for cars)
    final pricePerHour = listing.hourlyRateCar ?? listing.hourlyRateBike ?? 50.0;

    // Collect images - entrance photo first, then parking photos
    final images = <String>[];
    if (listing.entrancePhotoUrl != null) images.add(listing.entrancePhotoUrl!);
    images.addAll(listing.parkingPhotos);

    return ParkingSpaceCard(
      id: listing.id,
      name: listing.parkingSpaceName,
      address: listing.parkingAddress,
      pricePerHour: pricePerHour,
      availableSpots: listing.totalAvailableSlots,
      distanceInMeters: listingWithDistance.distanceInMeters,
      images: images,
      features: features,
      allAmenities: listing.amenities, // Store all amenities from database
      averageRating: 4.0, // TODO: Get from reviews table
      reviewCount: 0, // TODO: Get from reviews table
      isCovered: listing.amenities.any((a) => a.toLowerCase().contains('covered')),
      hasEvCharging: listing.amenities.any((a) => a.toLowerCase().contains('ev')),
      is24x7: listing.is24x7,
      // Add location data
      latitude: listing.latitude,
      longitude: listing.longitude,
      // Add pricing data
      hourlyRateCar: listing.hourlyRateCar,
      dailyRateCar: listing.dailyRateCar,
      hourlyRateBike: listing.hourlyRateBike,
      dailyRateBike: listing.dailyRateBike,
      // Add discount data
      hourlyDiscountCar: listing.hourlyDiscountCar,
      hourlyDiscountBike: listing.hourlyDiscountBike,
      dailyDiscountCar: listing.dailyDiscountCar,
      dailyDiscountBike: listing.dailyDiscountBike,
      hourlyDiscountCarPercent: listing.hourlyDiscountCarPercent,
      hourlyDiscountBikePercent: listing.hourlyDiscountBikePercent,
      dailyDiscountCarPercent: listing.dailyDiscountCarPercent,
      dailyDiscountBikePercent: listing.dailyDiscountBikePercent,
    );
  }

  static List<String> _extractFeatures(ParkingSpace space) {
    final features = <String>[];
    final desc = space.description.toLowerCase();

    if (desc.contains('covered')) features.add('Covered');
    if (desc.contains('cctv') || desc.contains('security')) features.add('CCTV');
    if (desc.contains('ev') || desc.contains('electric')) features.add('EV');
    if (desc.contains('24') || desc.contains('24/7')) features.add('24x7');
    if (desc.contains('valet')) features.add('Valet');

    return features.take(3).toList(); // Max 3 features
  }

  static List<String> _extractFeaturesFromAmenities(List<String> amenities) {
    final features = <String>[];

    for (final amenity in amenities) {
      switch (amenity.toLowerCase()) {
        case 'covered':
          features.add('Covered');
          break;
        case 'cctv':
        case 'security':
        case 'security_guard':
          if (!features.contains('CCTV')) features.add('CCTV');
          break;
        case 'ev_charging':
        case 'ev':
          features.add('EV');
          break;
        case '24x7':
        case '24/7':
          features.add('24x7');
          break;
        case 'valet':
          features.add('Valet');
          break;
      }
      if (features.length >= 3) break;
    }

    return features;
  }

  String get formattedDistance {
    // Calculate walking time (average walking speed: 5 km/h = 83.33 m/min = 1.39 m/s)
    // For simplicity: 100m ≈ 1 min walk
    final walkingMinutes = (distanceInMeters / 100).round();

    if (distanceInMeters < 100) {
      return '${distanceInMeters.round()}m away';
    } else if (distanceInMeters < 1000) {
      // Show both distance and walking time for < 1km
      return '${distanceInMeters.round()}m • $walkingMinutes min walk';
    } else {
      // For >= 1km, show km and walking time
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km • $walkingMinutes min';
    }
  }

  String get urgencyText {
    if (availableSpots <= 1) return 'Last spot!';
    if (availableSpots <= 3) return 'Only $availableSpots spots left';
    return '';
  }

  bool get isUrgent => availableSpots <= 3;

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

  // Get the maximum discount percentage across all discount types
  double get maxDiscountPercentage {
    double maxPercent = 0;

    // Check all percentage discounts
    if (hourlyDiscountCarPercent != null && hourlyDiscountCarPercent! > maxPercent) {
      maxPercent = hourlyDiscountCarPercent!;
    }
    if (hourlyDiscountBikePercent != null && hourlyDiscountBikePercent! > maxPercent) {
      maxPercent = hourlyDiscountBikePercent!;
    }
    if (dailyDiscountCarPercent != null && dailyDiscountCarPercent! > maxPercent) {
      maxPercent = dailyDiscountCarPercent!;
    }
    if (dailyDiscountBikePercent != null && dailyDiscountBikePercent! > maxPercent) {
      maxPercent = dailyDiscountBikePercent!;
    }

    return maxPercent;
  }

  // Get available vehicle types based on pricing availability
  List<String> getAvailableVehicleTypes() {
    final types = <String>[];
    if (hourlyRateCar != null || dailyRateCar != null) {
      types.add('Car');
    }
    if (hourlyRateBike != null || dailyRateBike != null) {
      types.add('Bike');
    }
    return types;
  }

  @override
  String toString() {
    return 'ParkingSpaceCard(name: $name, price: ₹$pricePerHour, distance: $formattedDistance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParkingSpaceCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Home Page Parking Spaces Notifier - Using listings table with availability
class HomeParkingNotifier extends StateNotifier<AsyncValue<List<ParkingSpaceCard>>> {
  final AsyncValue<LocationData?> _locationAsync;
  final HomeSearchFilters _filters;
  final ListingsService _listingService;

  HomeParkingNotifier(this._locationAsync, this._filters, this._listingService) : super(const AsyncValue.loading()) {
    _loadParkingSpaces();
  }

  Future<void> _loadParkingSpaces() async {
    // Check if disposed
    if (!mounted) return;

    // Check if location is still loading
    final isLocationLoading = _locationAsync.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    // If location is still loading, keep showing loading state
    if (isLocationLoading) {
      if (!mounted) return;
      state = const AsyncValue.loading();
      return;
    }

    final locationData = _locationAsync.maybeWhen(
      data: (location) => location,
      orElse: () => null,
    );

    // If location is null but not loading (error or no location), show empty
    if (locationData == null) {
      if (!mounted) return;
      state = const AsyncValue.data([]);
      return;
    }

    if (!mounted) return;
    state = const AsyncValue.loading();

    try {
      // Fetch parking listings from listings table joined with parking_active_slots
      final listings = await _listingService.getNearbyListings(
        userLocation: locationData,
        radiusInMeters: LocationService.defaultSearchRadius,
        limit: 50,
      );

      // Check if still mounted after async operation
      if (!mounted) return;

      // Convert to card format
      var cards = listings.map((listingWithDistance) =>
        ParkingSpaceCard.fromListing(listingWithDistance)
      ).toList();

      // Apply search filters
      if (_filters.location.isNotEmpty) {
        cards = cards.where((card) =>
          card.name.toLowerCase().contains(_filters.location.toLowerCase()) ||
          card.address.toLowerCase().contains(_filters.location.toLowerCase())
        ).toList();
      }

      // Apply amenity filters
      if (_filters.selectedFilters.contains('covered')) {
        cards = cards.where((card) => card.isCovered).toList();
      }
      if (_filters.selectedFilters.contains('ev')) {
        cards = cards.where((card) => card.hasEvCharging).toList();
      }
      if (_filters.selectedFilters.contains('24x7')) {
        cards = cards.where((card) => card.is24x7).toList();
      }

      // Apply price filter
      if (_filters.maxPrice != null) {
        cards = cards.where((card) => card.pricePerHour <= _filters.maxPrice!).toList();
      }

      // Apply sorting
      if (_filters.selectedFilters.contains('nearest')) {
        cards.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      } else if (_filters.selectedFilters.contains('cheapest')) {
        cards.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
      } else {
        // Default: sort by distance
        cards.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      }

      // Final mounted check before setting state
      if (!mounted) return;
      state = AsyncValue.data(cards);
    } catch (e, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    await _loadParkingSpaces();
  }

  void updateFilters(HomeSearchFilters newFilters) {
    if (!mounted) return;
    // This would trigger a reload with new filters
    // For now, we'll just reload with current location
    _loadParkingSpaces();
  }
}

// Provider for selected parking space (for detailed view)
final selectedParkingSpaceProvider = StateProvider<ParkingSpace?>((ref) => null);

// Provider for search query
final parkingSearchQueryProvider = StateProvider<String>((ref) => '');

// Home page search filters provider
final homeSearchFiltersProvider = StateProvider<HomeSearchFilters>((ref) => HomeSearchFilters.initial());

// Home page parking spaces provider
// Uses searched location if available, otherwise uses current location
final homeParkingSpacesProvider = StateNotifierProvider<HomeParkingNotifier, AsyncValue<List<ParkingSpaceCard>>>((ref) {
  final searchedLocation = ref.watch(searchedLocationProvider);
  final currentLocationAsync = ref.watch(currentLocationProvider);
  final filters = ref.watch(homeSearchFiltersProvider);
  final listingService = ref.watch(listingsServiceProvider);

  // Use searched location if available, otherwise use current location
  final locationAsync = searchedLocation != null
    ? AsyncValue.data(searchedLocation)
    : currentLocationAsync;

  return HomeParkingNotifier(locationAsync, filters, listingService);
});

// Map view toggle provider
final mapViewProvider = StateProvider<bool>((ref) => false);

// Filtered parking spaces based on search query
final filteredParkingSpacesProvider = Provider<AsyncValue<List<ParkingSpace>>>((ref) {
  final parkingSpacesAsync = ref.watch(parkingSpacesProvider);
  final searchQuery = ref.watch(parkingSearchQueryProvider);

  return parkingSpacesAsync.when(
    data: (parkingSpaces) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(parkingSpaces);
      }

      final filteredSpaces = parkingSpaces.where((space) {
        return space.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               space.address.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();

      return AsyncValue.data(filteredSpaces);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
