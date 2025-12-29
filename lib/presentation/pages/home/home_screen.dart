import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../providers/parking_provider.dart';
import 'widgets/quick_filters_row.dart';
import 'widgets/parking_space_card.dart';
import 'widgets/parking_card_skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();

    // Initialize current location when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationNotifier = ref.read(currentLocationProvider.notifier);
      locationNotifier.getCurrentLocation();
    });

    // Listen to scroll position for scroll-to-top button
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final showButton = _scrollController.offset > 200;
        if (showButton != _showScrollToTopButton) {
          setState(() {
            _showScrollToTopButton = showButton;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _refreshParkingSpaces() async {
    try {
      // Refresh both location and parking spaces
      await _refreshLocation();
      final parkingNotifier = ref.read(homeParkingSpacesProvider.notifier);
      await parkingNotifier.refresh();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }

  Future<void> _refreshLocation() async {
    try {
      // Refresh current location
      final locationNotifier = ref.read(currentLocationProvider.notifier);
      await locationNotifier.getCurrentLocation();
    } catch (e) {
      debugPrint('Error refreshing location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final parkingSpacesAsync = ref.watch(homeParkingSpacesProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: _buildListView(parkingSpacesAsync),
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.ctaPrimary,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeroHeader() {
    final locationAsync = ref.watch(currentLocationProvider);

    return Container(
      height: 200, // Increased height to accommodate larger filter chips
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.8), // Dark at top
            Colors.black.withOpacity(0.4), // Medium dark in middle
            Colors.white.withOpacity(0.9), // Light/white at bottom
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppConstants.spacing24, vertical: AppConstants.spacing32),
          child: Column(
            children: [
              // Top row with location and greeting
              Row(
                children: [
                  // Location and greeting section - left side
                  Expanded(
                    flex: 3, // Take 3/4 of the width
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Greeting
                        Text(
                          'Good ${_getTimeOfDay()}!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: AppConstants.spacing12),

                        // Location with animated loading
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: locationAsync.when(
                            data: (location) {
                              if (location == null) {
                                return _buildLocationPlaceholder('Getting your location...');
                              }
                              return _buildLocationDisplay(location.displayAddress);
                            },
                            loading: () => _buildLocationPlaceholder('Finding your location...'),
                            error: (_, __) => _buildLocationError(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action button - right side
                  Expanded(
                    flex: 1, // Take 1/4 of the width
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppConstants.radius12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.my_location,
                            color: AppColors.ctaPrimary,
                            size: 20,
                          ),
                          onPressed: _refreshLocation,
                          tooltip: 'Refresh location',
                          padding: EdgeInsets.all(AppConstants.spacing8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        SizedBox(height: AppConstants.spacing4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPlaceholder(String text) {
    return Row(
      key: ValueKey('location_placeholder'),
      children: [
        Container(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
        SizedBox(width: AppConstants.spacing8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDisplay(String address) {
    return Row(
      key: ValueKey('location_display'),
      children: [
        Icon(
          Icons.location_on,
          color: Colors.white70,
          size: 16,
        ),
        SizedBox(width: AppConstants.spacing8),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationError() {
    return Row(
      key: ValueKey('location_error'),
      children: [
        Icon(
          Icons.location_off,
          color: Colors.red.shade400,
          size: 16,
        ),
        SizedBox(width: AppConstants.spacing8),
        Expanded(
          child: Text(
            'Location unavailable',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
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
              Icons.local_parking_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: AppConstants.spacing24),
          Text(
            'No parking available nearby',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing12),
          Text(
            'Try changing your search location or filters to find more parking spaces',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Open search modal or refresh
              final notifier = ref.read(homeParkingSpacesProvider.notifier);
              notifier.refresh();
            },
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPrimary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing24,
                vertical: AppConstants.spacing12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(AppConstants.radius24),
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
          ),
          SizedBox(height: AppConstants.spacing24),
          Text(
            'Unable to load parking spaces',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing12),
          Text(
            'Please check your internet connection and try again',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing32),
          ElevatedButton.icon(
            onPressed: () {
              final notifier = ref.read(homeParkingSpacesProvider.notifier);
              notifier.refresh();
            },
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPrimary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing24,
                vertical: AppConstants.spacing12,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildListView(AsyncValue<List<ParkingSpaceCard>> parkingSpacesAsync) {
    return RefreshIndicator(
      onRefresh: _refreshParkingSpaces,
      color: AppColors.ctaPrimary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Hero header with greeting and location
          SliverToBoxAdapter(
            child: _buildHeroHeader(),
          ),

          // Quick filters row
          const SliverToBoxAdapter(
            child: QuickFiltersRow(),
          ),

          // Results header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing12,
              ),
              child: Text(
                'Available Parking Today',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Parking spaces list
          parkingSpacesAsync.when(
            data: (parkingSpaces) {
              if (parkingSpaces.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final parkingSpace = parkingSpaces[index];
                    return ParkingSpaceCardWidget(card: parkingSpace);
                  },
                  childCount: parkingSpaces.length,
                ),
              );
            },
            loading: () => SliverToBoxAdapter(
              child: const ParkingCardsLoadingState(itemCount: 3),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: _buildErrorState(error),
            ),
          ),

          // Bottom spacing
          SliverToBoxAdapter(
            child: SizedBox(height: AppConstants.spacing32),
          ),
        ],
      ),
    );
  }
}
