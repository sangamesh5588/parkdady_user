import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../services/places_service.dart';
import '../../../services/location_service.dart';
import '../../../services/listings_service.dart';
import '../../providers/parking_provider.dart';
import '../../widgets/custom_button.dart';
import '../home/widgets/parking_space_card.dart';
import '../home/widgets/parking_card_skeleton.dart';
import 'widgets/search_parking_card.dart';



class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _searchBarController;
  late Animation<double> _searchBarAnimation;

  bool _isSearchFocused = false;
  String _selectedTimeFilter = 'Now';
  String _selectedVehicleFilter = 'Car';
  String _selectedPriceFilter = 'Any';
  String _sortBy = 'Distance';

  List<ParkingSpaceCard> _searchResults = [];

  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentQuery = '';

  // Places API suggestions
  List<PlaceSuggestion> _placeSuggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;

  // Voice search state
  bool _isListening = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
      value: 1.0, // Start at 1.0 to avoid opacity issues
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _searchBarController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
      value: 1.0, // Start at 1.0 to avoid animation issues
    );
    _searchBarAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchBarController, curve: Curves.elasticOut),
    );


  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    _searchBarController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't reset state on every dependency change - only on first build
    debugPrint('Search screen dependencies changed');
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = []; // Clear previous results
    });

    try {
      // Search for parking listings matching the query (address, name, or landmark)
      final listingsService = ListingsService();
      final listings = await listingsService.searchListings(
        query: query,
        limit: 50,
      );

      if (!mounted) return;

      // Convert listings to ParkingSpaceCard
      final results = <ParkingSpaceCard>[];
      for (final listing in listings) {
        // Calculate distance if we have coordinates
        double distanceInMeters = 0.0;
        if (listing.latitude != null && listing.longitude != null) {
          try {
            final currentLocation = await LocationService().getCurrentLocation();
            if (currentLocation != null) {
              distanceInMeters = LocationService().calculateDistance(
                currentLocation.latitude,
                currentLocation.longitude,
                listing.latitude!,
                listing.longitude!,
              );
            }
          } catch (e) {
            debugPrint('Error calculating distance: $e');
          }
        }

        // Get active slots count
        final carSlots = listing.activeCarSlots ?? 0;
        final bikeSlots = listing.activeBikeSlots ?? 0;

        // Determine price based on vehicle filter
        final price = _selectedVehicleFilter == 'Car'
            ? (listing.hourlyRateCar ?? 0.0)
            : (listing.hourlyRateBike ?? 0.0);

        // Extract key features from amenities
        final features = listing.amenities.take(3).toList();

        results.add(ParkingSpaceCard(
          id: listing.id,
          name: listing.parkingSpaceName,
          address: listing.parkingAddress,
          pricePerHour: price,
          distanceInMeters: distanceInMeters,
          availableSpots: _selectedVehicleFilter == 'Car' ? carSlots : bikeSlots,
          images: [
            if (listing.entrancePhotoUrl != null) listing.entrancePhotoUrl!,
            ...listing.parkingPhotos,
          ],
          features: features,
          allAmenities: listing.amenities,
          averageRating: 4.5, // Default rating
          reviewCount: 0,
          isCovered: listing.amenities.contains('Covered Parking'),
          hasEvCharging: listing.amenities.contains('EV Charging'),
          is24x7: listing.is24x7,
          latitude: listing.latitude,
          longitude: listing.longitude,
          hourlyRateCar: listing.hourlyRateCar,
          dailyRateCar: listing.dailyRateCar,
          hourlyRateBike: listing.hourlyRateBike,
          dailyRateBike: listing.dailyRateBike,
          hourlyDiscountCar: listing.hourlyDiscountCar,
          hourlyDiscountBike: listing.hourlyDiscountBike,
          dailyDiscountCar: listing.dailyDiscountCar,
          dailyDiscountBike: listing.dailyDiscountBike,
          hourlyDiscountCarPercent: listing.hourlyDiscountCarPercent,
          hourlyDiscountBikePercent: listing.hourlyDiscountBikePercent,
          dailyDiscountCarPercent: listing.dailyDiscountCarPercent,
          dailyDiscountBikePercent: listing.dailyDiscountBikePercent,
        ));
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint('Error performing search: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search parking spaces: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchQueryChanged(String query) {
    print('🔤 Search query changed: "$query"');
    setState(() => _currentQuery = query);

    // Clear previous timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      print('⚠️ Query is empty, clearing suggestions');
      setState(() {
        _placeSuggestions = [];
        _hasSearched = false;
        _isLoadingSuggestions = false;
      });
      return;
    }

    print('⏱️ Starting debounce timer (300ms) for query: "$query"');
    // Debounce the API call
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      print('✅ Debounce timer completed, fetching suggestions');
      _fetchPlaceSuggestions(query);
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    if (!mounted) return;

    setState(() => _isLoadingSuggestions = true);

    try {
      final placesService = PlacesService();
      final suggestions = await placesService.getPlaceSuggestions(query);

      if (mounted) {
        setState(() {
          _placeSuggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _placeSuggestions = [];
          _isLoadingSuggestions = false;
        });
        debugPrint('Error fetching place suggestions: $e');

        // Show error to user if API fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to fetch location suggestions. Please check your internet connection.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    _searchController.text = suggestion.description;
    setState(() {
      _currentQuery = suggestion.description;
      _placeSuggestions = [];
      _isLoading = true;
      _hasSearched = true;
    });
    _searchFocusNode.unfocus();

    try {
      // Get place details with coordinates
      final placesService = PlacesService();
      final placeDetails = await placesService.getPlaceDetails(suggestion.placeId);

      print('📍 Selected location: ${placeDetails.name}');
      print('📍 Coordinates: ${placeDetails.latitude}, ${placeDetails.longitude}');

      // Search for parking listings near this location
      await _searchNearbyParking(
        placeDetails.latitude,
        placeDetails.longitude,
        placeDetails.name,
      );
    } catch (e) {
      debugPrint('Error getting place details: $e');
      // Fallback to text search
      await _performSearch(suggestion.description);
    }
  }

  Future<void> _searchNearbyParking(
    double latitude,
    double longitude,
    String locationName,
  ) async {
    try {
      final listingsService = ListingsService();

      // Get all listings (we'll filter by distance)
      final allListings = await listingsService.searchListings(
        query: '', // Empty query to get all listings
        limit: 100,
      );

      if (!mounted) return;

      // Calculate distance for each listing and filter nearby ones
      final nearbyListings = <ParkingSpaceCard>[];

      for (final listing in allListings) {
        if (listing.latitude == null || listing.longitude == null) continue;

        // Calculate distance from selected location
        final distance = LocationService().calculateDistance(
          latitude,
          longitude,
          listing.latitude!,
          listing.longitude!,
        );

        // Only include listings within 10km
        if (distance <= 10000) {
          // Get active slots count
          final carSlots = listing.activeCarSlots ?? 0;
          final bikeSlots = listing.activeBikeSlots ?? 0;

          // Determine price based on vehicle filter
          final price = _selectedVehicleFilter == 'Car'
              ? (listing.hourlyRateCar ?? 0.0)
              : (listing.hourlyRateBike ?? 0.0);

          // Extract key features from amenities
          final features = listing.amenities.take(3).toList();

          nearbyListings.add(ParkingSpaceCard(
            id: listing.id,
            name: listing.parkingSpaceName,
            address: listing.parkingAddress,
            pricePerHour: price,
            distanceInMeters: distance,
            availableSpots: _selectedVehicleFilter == 'Car' ? carSlots : bikeSlots,
            images: [
              if (listing.entrancePhotoUrl != null) listing.entrancePhotoUrl!,
              ...listing.parkingPhotos,
            ],
            features: features,
            allAmenities: listing.amenities,
            averageRating: 4.5,
            reviewCount: 0,
            isCovered: listing.amenities.contains('Covered Parking'),
            hasEvCharging: listing.amenities.contains('EV Charging'),
            is24x7: listing.is24x7,
            latitude: listing.latitude,
            longitude: listing.longitude,
            hourlyRateCar: listing.hourlyRateCar,
            dailyRateCar: listing.dailyRateCar,
            hourlyRateBike: listing.hourlyRateBike,
            dailyRateBike: listing.dailyRateBike,
            hourlyDiscountCar: listing.hourlyDiscountCar,
            hourlyDiscountBike: listing.hourlyDiscountBike,
            dailyDiscountCar: listing.dailyDiscountCar,
            dailyDiscountBike: listing.dailyDiscountBike,
            hourlyDiscountCarPercent: listing.hourlyDiscountCarPercent,
            hourlyDiscountBikePercent: listing.hourlyDiscountBikePercent,
            dailyDiscountCarPercent: listing.dailyDiscountCarPercent,
            dailyDiscountBikePercent: listing.dailyDiscountBikePercent,
          ));
        }
      }

      // Sort by distance
      nearbyListings.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = nearbyListings;
        });

        print('✅ Found ${nearbyListings.length} parking spots near $locationName');
      }
    } catch (e) {
      debugPrint('Error searching nearby parking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search parking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleAdvancedFilters() {
    // Filter icon is now just a visual element - no functionality
    // Keeping the method for future implementation
  }

  void _showFilterBottomSheet() {
    // Show filter options bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radius16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(AppConstants.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Filter Parking',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Reset filters
                      setState(() {
                        _selectedTimeFilter = 'Now';
                        _selectedVehicleFilter = 'Car';
                        _selectedPriceFilter = 'Any';
                        _sortBy = 'Distance';
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: AppColors.ctaPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacing20),

              // Filters content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Vehicle Type Filter
                    _buildFilterSection(
                      title: 'Vehicle Type',
                      child: StatefulBuilder(
                        builder: (context, setState) => _buildVehicleFilterOptions(setState),
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing24),

                    // Price Range Filter (Low to High)
                    _buildFilterSection(
                      title: 'Price Range (per hour)',
                      child: StatefulBuilder(
                        builder: (context, setState) => _buildPriceRangeFilterOptions(setState),
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing24),

                    // Sort By
                    _buildFilterSection(
                      title: 'Sort By',
                      child: StatefulBuilder(
                        builder: (context, setState) => _buildSortOptions(setState),
                      ),
                    ),
                  ],
                ),
              ),

              // Apply Button
              SizedBox(height: AppConstants.spacing20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Apply filters to current search results
                    _applyFiltersToResults();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaPrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: AppConstants.spacing16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radius12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.getPrimaryText(context),
          ),
        ),
        SizedBox(height: AppConstants.spacing12),
        child,
      ],
    );
  }



  Widget _buildVehicleFilterOptions(StateSetter setState) {
    final options = ['Car', 'Bike', 'Truck', 'EV'];
    return Wrap(
      spacing: AppConstants.spacing8,
      runSpacing: AppConstants.spacing8,
      children: options.map((option) => _buildSelectableChip(
        label: option,
        isSelected: _selectedVehicleFilter == option,
        onTap: () => setState(() => _selectedVehicleFilter = option),
      )).toList(),
    );
  }

  Widget _buildPriceRangeFilterOptions(StateSetter setState) {
    final options = ['₹0-₹50', '₹50-₹100', '₹100-₹200', '₹200+'];
    return Wrap(
      spacing: AppConstants.spacing8,
      runSpacing: AppConstants.spacing8,
      children: options.map((option) => _buildSelectableChip(
        label: option,
        isSelected: _selectedPriceFilter == option,
        onTap: () => setState(() => _selectedPriceFilter = option),
      )).toList(),
    );
  }

  Widget _buildSortOptions(StateSetter setState) {
    final options = ['Distance', 'Price', 'Rating'];
    return Wrap(
      spacing: AppConstants.spacing8,
      runSpacing: AppConstants.spacing8,
      children: options.map((option) => _buildSelectableChip(
        label: option,
        isSelected: _sortBy == option,
        onTap: () => setState(() => _sortBy = option),
      )).toList(),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radius20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
          vertical: AppConstants.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.ctaPrimary.withOpacity(0.1)
              : AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(AppConstants.radius20),
          border: Border.all(
            color: isSelected
                ? AppColors.ctaPrimary
                : AppColors.divider.withOpacity(0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.ctaPrimary
                : AppColors.getPrimaryText(context),
          ),
        ),
      ),
    );
  }

  void _applyFiltersToResults() {
    if (_searchResults.isNotEmpty) {
      setState(() {
        // Sort results based on selected sort option
        _sortResults();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filters applied to search results')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Custom scroll view with sticky header
              CustomScrollView(
                slivers: [
                  // Sticky search bar header
                  SliverAppBar(
                    backgroundColor: AppColors.primaryBackground,
                    elevation: 0,
                    pinned: false,
                    floating: true,
                    snap: true,
                    toolbarHeight: 80, // Height for search bar + padding
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: EdgeInsets.only(
                          left: AppConstants.spacing16,
                          right: AppConstants.spacing16,
                          top: AppConstants.spacing16,
                          bottom: AppConstants.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBackground,
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.divider.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            _buildCompactSearchBar(),
                            // Clear button when there's text, filter icon otherwise
                            Positioned(
                              top: 0,
                              right: 0,
                              child: _searchController.text.isNotEmpty
                                  ? _buildClearButton()
                                  : _buildSingleFilterIcon(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Place suggestions overlay (when typing)
                  if (_placeSuggestions.isNotEmpty && _currentQuery.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildPlaceSuggestionsDropdown(),
                    ),

                  // Filters row (only show in list view, not in map view)
                  // Removed - keeping only the corner filter icon

                  // Search results or suggestions
                  if (_hasSearched)
                    // List view
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final parkingSpace = _searchResults[index];
                          return SearchParkingCardWidget(card: parkingSpace);
                        },
                        childCount: _searchResults.length,
                      ),
                    )
                  else if (_placeSuggestions.isEmpty || _currentQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildSearchSuggestions(),
                    ),
                ],
              ),

              // Voice search overlay
              if (_isListening) _buildVoiceSearchOverlay(),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.spacing16,
        right: AppConstants.spacing16,
        top: AppConstants.spacing16,
        bottom: AppConstants.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button (proper navigation stack)
          IconButton(
            onPressed: () {
              // Try to pop current route first (go back in navigation stack)
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // If no route to pop (we're at root), go to home tab
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.getPrimaryText(context),
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          SizedBox(width: AppConstants.spacing16),

          // Compact search bar (takes full width)
          Expanded(
            child: _buildCompactSearchBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSearchBar() {
    return Container(
      height: 48, // Compact height
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchQueryChanged,
        decoration: InputDecoration(
          hintText: 'Search location...',
          hintStyle: TextStyle(
            color: AppColors.getSecondaryText(context),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.ctaPrimary,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentQuery = '';
                      _hasSearched = false;
                      _placeSuggestions = [];
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.getSecondaryText(context),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacing12,
            vertical: AppConstants.spacing12,
          ),
        ),
        style: TextStyle(
          color: AppColors.getPrimaryText(context),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSearchBarWithSuggestions() {
    return Column(
      children: [
        // Search bar
        Container(
          margin: EdgeInsets.all(AppConstants.spacing16),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(AppConstants.radius16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (query) {
              setState(() => _currentQuery = query);
              if (query.isNotEmpty) {
                _performSearch(query);
              } else {
                setState(() => _hasSearched = false);
              }
            },
            decoration: InputDecoration(
              hintText: 'Where are you going?',
              hintStyle: TextStyle(
                color: AppColors.getSecondaryText(context),
                fontSize: 16,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(AppConstants.spacing12),
                child: Icon(
                  Icons.search,
                  color: AppColors.ctaPrimary,
                  size: 24,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _currentQuery = '';
                          _hasSearched = false;
                        });
                      },
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.getSecondaryText(context),
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      // Use current location
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Using current location')),
                      );
                    },
                    icon: Icon(
                      Icons.my_location,
                      color: AppColors.ctaPrimary,
                    ),
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing16,
              ),
            ),
            style: TextStyle(
              color: AppColors.getPrimaryText(context),
              fontSize: 16,
            ),
          ),
        ),

        // Search suggestions dropdown (when focused and has query)
        if (_isSearchFocused && _currentQuery.isNotEmpty) _buildMockSearchSuggestionsDropdown(),
      ],
    );
  }

  Widget _buildPlaceSuggestionsDropdown() {
    if (_isLoadingSuggestions) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
        padding: EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          boxShadow: [AppColors.mediumShadow],
          border: Border.all(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaPrimary),
              ),
            ),
            SizedBox(width: AppConstants.spacing12),
            Text(
              'Finding places...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryText(context),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        boxShadow: [AppColors.mediumShadow],
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _placeSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _placeSuggestions[index];
          return InkWell(
            onTap: () => _onSuggestionSelected(suggestion),
            child: Container(
              padding: EdgeInsets.all(AppConstants.spacing16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.ctaPrimary,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.mainText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPrimaryText(context),
                          ),
                        ),
                        if (suggestion.secondaryText.isNotEmpty) ...[
                          SizedBox(height: AppConstants.spacing4),
                          Text(
                            suggestion.secondaryText,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.getSecondaryText(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.getSecondaryText(context),
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMockSearchSuggestionsDropdown() {
    final suggestions = _getSearchSuggestions(_currentQuery);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        boxShadow: [AppColors.mediumShadow],
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return InkWell(
            onTap: () {
              _searchController.text = suggestion;
              setState(() => _currentQuery = suggestion);
              _performSearch(suggestion);
              _searchFocusNode.unfocus();
            },
            child: Container(
              padding: EdgeInsets.all(AppConstants.spacing16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.ctaPrimary,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.spacing12),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.getPrimaryText(context),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.getSecondaryText(context),
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildQuickFilterChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.ctaPrimary : AppColors.primaryBackground,
      borderRadius: BorderRadius.circular(AppConstants.radius20),
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacing16,
            vertical: AppConstants.spacing8,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.getButtonPrimaryText(context)
                    : AppColors.ctaPrimary,
              ),
              SizedBox(width: AppConstants.spacing8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.getButtonPrimaryText(context)
                      : AppColors.ctaPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilterChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radius20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacing16,
            vertical: AppConstants.spacing8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radius20),
            border: Border.all(
              color: isSelected ? Colors.black : AppColors.divider.withOpacity(0.5),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Smaller icon without background
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.black,
              ),
              SizedBox(width: AppConstants.spacing4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildClearButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radius20),
      child: InkWell(
        onTap: () {
          _searchController.clear();
          setState(() {
            _currentQuery = '';
            _hasSearched = false;
            _placeSuggestions = [];
          });
        },
        borderRadius: BorderRadius.circular(AppConstants.radius20),
        child: Container(
          padding: EdgeInsets.all(AppConstants.spacing12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radius20),
            border: Border.all(
              color: AppColors.divider.withOpacity(0.5),
              width: 1.0,
            ),
          ),
          child: Icon(
            Icons.clear,
            size: 20,
            color: AppColors.getSecondaryText(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleFilterIcon() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radius20),
      child: InkWell(
        onTap: () => _showFilterBottomSheet(),
        borderRadius: BorderRadius.circular(AppConstants.radius20),
        child: Container(
          padding: EdgeInsets.all(AppConstants.spacing12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radius20),
            border: Border.all(
              color: AppColors.divider.withOpacity(0.5),
              width: 1.0,
            ),
          ),
          child: Icon(
            Icons.tune,
            size: 20,
            color: Colors.black,
          ),
        ),
      ),
    );
  }







  Widget _buildSearchResults() {
    if (_isLoading) {
      return const ParkingCardsLoadingState(itemCount: 3);
    }

    if (_hasSearched && _searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildListView();
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final parkingSpace = _searchResults[index];
        return ParkingSpaceCardWidget(card: parkingSpace);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppConstants.radius24),
            ),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.getSecondaryText(context),
            ),
          ),
          SizedBox(height: AppConstants.spacing24),
          Text(
            'No parking found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.getPrimaryText(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing12),
          Text(
            'Try adjusting your search criteria or location',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.getSecondaryText(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing32),
          SizedBox(
            width: 200,
            child: CustomButton(
              text: 'Clear Filters',
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _hasSearched = false;
                  _searchResults = [];
                });
              },
              variant: CustomButtonVariant.outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search prompt
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: AppConstants.spacing32),
              Icon(
                Icons.search,
                size: 64,
                color: AppColors.getSecondaryText(context).withOpacity(0.5),
              ),
              SizedBox(height: AppConstants.spacing16),
              Text(
                'Search for parking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getPrimaryText(context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.spacing8),
              Text(
                'Enter a location or use your current location to find parking spots',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getSecondaryText(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.spacing32),
            ],
          ),

          // Popular areas section
          Text(
            'Popular areas in Bangalore',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          SizedBox(height: AppConstants.spacing16),

          // Popular areas grid
          _buildPopularAreasGrid(),
        ],
      ),
    );
  }

  Widget _buildPopularAreasGrid() {
    final popularAreas = [
      'Koramangala',
      'Indiranagar',
      'Whitefield',
      'MG Road',
      'Jayanagar',
      'Rajajinagar',
      'Malleshwaram',
      'Frazer Town',
      'Brigade Road',
      'Electronic City',
      'HSR Layout',
      'Marathahalli',
      'BTM Layout',
      'Banashankari',
      'Basavanagudi',
    ];

    return Wrap(
      spacing: AppConstants.spacing12,
      runSpacing: AppConstants.spacing12,
      children: popularAreas.map((area) => _buildAreaChip(area)).toList(),
    );
  }

  Widget _buildAreaChip(String areaName) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.radius20),
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      child: InkWell(
        onTap: () => _searchAreaByLocation(areaName),
        borderRadius: BorderRadius.circular(AppConstants.radius20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacing16,
            vertical: AppConstants.spacing8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radius20),
            border: Border.all(
              color: AppColors.divider.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.ctaPrimary,
              ),
              SizedBox(width: AppConstants.spacing8),
              Text(
                areaName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getPrimaryText(context),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bangalore area coordinates (approximate center points)
  Map<String, LocationData> get _bangaloreAreas => {
    'Koramangala': LocationData(
      latitude: 12.9352,
      longitude: 77.6245,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Koramangala, Bangalore',
    ),
    'Indiranagar': LocationData(
      latitude: 12.9784,
      longitude: 77.6408,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Indiranagar, Bangalore',
    ),
    'Whitefield': LocationData(
      latitude: 12.9698,
      longitude: 77.7500,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Whitefield, Bangalore',
    ),
    'MG Road': LocationData(
      latitude: 12.9759,
      longitude: 77.6033,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'MG Road, Bangalore',
    ),
    'Jayanagar': LocationData(
      latitude: 12.9299,
      longitude: 77.5824,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Jayanagar, Bangalore',
    ),
    'Rajajinagar': LocationData(
      latitude: 12.9882,
      longitude: 77.5540,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Rajajinagar, Bangalore',
    ),
    'Malleshwaram': LocationData(
      latitude: 13.0058,
      longitude: 77.5649,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Malleshwaram, Bangalore',
    ),
    'Frazer Town': LocationData(
      latitude: 12.9980,
      longitude: 77.6150,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Frazer Town, Bangalore',
    ),
    'Brigade Road': LocationData(
      latitude: 12.9719,
      longitude: 77.6070,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Brigade Road, Bangalore',
    ),
    'Electronic City': LocationData(
      latitude: 12.8452,
      longitude: 77.6633,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Electronic City, Bangalore',
    ),
    'HSR Layout': LocationData(
      latitude: 12.9081,
      longitude: 77.6476,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'HSR Layout, Bangalore',
    ),
    'Marathahalli': LocationData(
      latitude: 12.9553,
      longitude: 77.7011,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Marathahalli, Bangalore',
    ),
    'BTM Layout': LocationData(
      latitude: 12.9166,
      longitude: 77.6101,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'BTM Layout, Bangalore',
    ),
    'Banashankari': LocationData(
      latitude: 12.9255,
      longitude: 77.5464,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Banashankari, Bangalore',
    ),
    'Basavanagudi': LocationData(
      latitude: 12.9417,
      longitude: 77.5750,
      accuracy: 10.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      timestamp: DateTime.now(),
      address: 'Basavanagudi, Bangalore',
    ),
  };

  Future<void> _searchAreaByLocation(String areaName) async {
    final areaLocation = _bangaloreAreas[areaName];
    if (areaLocation == null) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      // Fetch nearby listings using the area coordinates as "user location"
      final listingsService = ListingsService();
      final nearbyListings = await listingsService.getNearbyListings(
        userLocation: areaLocation,
        radiusInMeters: LocationService.defaultSearchRadius,
        limit: 20,
      );

      // Convert to ParkingSpaceCard format for display
      final parkingCards = nearbyListings.map((listingWithDistance) {
        return ParkingSpaceCard.fromListing(listingWithDistance);
      }).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = parkingCards;
        });

        // Populate search field with area name
        _searchController.text = areaName;
        setState(() => _currentQuery = areaName);

        // Show success message with count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${parkingCards.length} parking spots in $areaName')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding parking in $areaName: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildEnhancedSuggestionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16, vertical: AppConstants.spacing4),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.divider.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radius16),
          child: Container(
            padding: EdgeInsets.all(AppConstants.spacing20),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.ctaPrimary.withOpacity(0.2),
                        AppColors.ctaPrimary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                    border: Border.all(
                      color: AppColors.ctaPrimary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.ctaPrimary,
                    size: 24,
                  ),
                ),

                SizedBox(width: AppConstants.spacing16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getPrimaryText(context),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          // Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppConstants.spacing8,
                              vertical: AppConstants.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(AppConstants.radius20),
                              border: Border.all(
                                color: badgeTextColor.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeTextColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.spacing8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getSecondaryText(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow with subtle animation hint
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(AppConstants.radius8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.getSecondaryText(context),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16, vertical: AppConstants.spacing4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        child: Container(
          padding: EdgeInsets.all(AppConstants.spacing16),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(AppConstants.radius12),
            border: Border.all(
              color: AppColors.divider,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.ctaPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radius8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.ctaPrimary,
                  size: 20,
                ),
              ),
              SizedBox(width: AppConstants.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryText(context),
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getSecondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.getSecondaryText(context),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceSearchOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(AppConstants.spacing32),
          margin: EdgeInsets.all(AppConstants.spacing32),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(AppConstants.radius20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              SizedBox(height: AppConstants.spacing20),
              Text(
                'Listening...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getPrimaryText(context),
                ),
              ),
              SizedBox(height: AppConstants.spacing8),
              Text(
                'Say the destination you\'re looking for',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.getSecondaryText(context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.spacing24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _stopVoiceSearch,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.ctaPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacing24),
                  ElevatedButton(
                    onPressed: _stopVoiceSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing24,
                        vertical: AppConstants.spacing12,
                      ),
                    ),
                    child: Text('Stop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimeFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radius16)),
      ),
      builder: (context) => _buildFilterOptionsSheet(
        title: 'Select Time',
        options: ['Now', 'Tonight', 'Tomorrow', 'This Week'],
        selectedValue: _selectedTimeFilter,
        onSelected: (value) => setState(() => _selectedTimeFilter = value),
      ),
    );
  }



  Widget _buildFilterOptionsSheet({
    required String title,
    required List<String> options,
    required String selectedValue,
    required Function(String) onSelected,
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          SizedBox(height: AppConstants.spacing16),
          ...options.map((option) => _buildFilterOption(
                option: option,
                isSelected: option == selectedValue,
                onTap: () {
                  onSelected(option);
                  Navigator.of(context).pop();
                },
              )),
        ],
      ),
    );
  }

  Widget _buildFilterOption({
    required String option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radius8),
      child: Container(
        padding: EdgeInsets.all(AppConstants.spacing16),
        margin: EdgeInsets.only(bottom: AppConstants.spacing8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.ctaPrimary.withOpacity(0.1)
              : AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(AppConstants.radius8),
          border: Border.all(
            color: isSelected
                ? AppColors.ctaPrimary
                : AppColors.divider,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.ctaPrimary
                      : AppColors.getPrimaryText(context),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: AppColors.ctaPrimary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  List<String> _getSearchSuggestions(String query) {
    // Mock suggestions - in real app, this would come from API
    final allSuggestions = [
      'Downtown Parking',
      'Airport Parking',
      'Mall Central Parking',
      'Train Station Parking',
      'Hospital Parking',
      'University Campus',
      'Business District',
      'Shopping Center',
    ];

    return allSuggestions
        .where((suggestion) =>
            suggestion.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  void _sortResults() {
    setState(() {
      switch (_sortBy) {
        case 'Distance':
          _searchResults.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
          break;
        case 'Price':
          _searchResults.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
          break;
        case 'Rating':
          _searchResults.sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
          break;
      }
    });
  }

  void _startVoiceSearch() {
    setState(() => _isListening = true);
    // Simulate voice search delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isListening = false);
        _searchController.text = 'Downtown Parking';
        _performSearch('Downtown Parking');
      }
    });
  }

  Future<void> _findParkingNearMe() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      // Get current location
      final locationService = LocationService();
      final userLocation = await locationService.getCurrentLocation();

      if (userLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to get your location. Please enable location services.')),
          );
          setState(() {
            _isLoading = false;
            _hasSearched = false;
          });
        }
        return;
      }

      // Fetch nearby listings with active slots (from listings + parking_active_slots join)
      final listingsService = ListingsService();
      final nearbyListings = await listingsService.getNearbyListings(
        userLocation: userLocation,
        radiusInMeters: LocationService.defaultSearchRadius,
        limit: 20,
      );

      // Convert to ParkingSpaceCard format for display
      final parkingCards = nearbyListings.map((listingWithDistance) {
        return ParkingSpaceCard.fromListing(listingWithDistance);
      }).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = parkingCards;
        });

        // Show success message with count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${parkingCards.length} parking spots near you')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding parking near you: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      // Get current location
      final locationService = LocationService();
      final userLocation = await locationService.getCurrentLocation();

      if (userLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to get your location. Please enable location services.')),
          );
          setState(() {
            _isLoading = false;
            _hasSearched = false;
          });
        }
        return;
      }

      // Get address from coordinates for better UX
      final address = await locationService.getAddressFromCoordinates(
        userLocation.latitude,
        userLocation.longitude,
      );

      // Fetch nearby listings using the same logic as home page
      final listingsService = ListingsService();
      final nearbyListings = await listingsService.getNearbyListings(
        userLocation: userLocation,
        radiusInMeters: LocationService.defaultSearchRadius,
        limit: 20,
      );

      // Convert to ParkingSpaceCard format for display (same as home page)
      final parkingCards = nearbyListings.map((listingWithDistance) {
        return ParkingSpaceCard.fromListing(listingWithDistance);
      }).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = parkingCards;
        });

        // Populate search field with current location
        final locationText = address ?? '${userLocation.latitude.toStringAsFixed(4)}, ${userLocation.longitude.toStringAsFixed(4)}';
        _searchController.text = locationText;
        setState(() => _currentQuery = locationText);

        // Show success message with count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${parkingCards.length} parking spots near you')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding parking near you: ${e.toString()}')),
        );
      }
    }
  }

  void _stopVoiceSearch() {
    setState(() => _isListening = false);
  }
}
