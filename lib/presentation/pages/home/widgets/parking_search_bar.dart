import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../providers/parking_provider.dart';

class ParkingSearchBar extends ConsumerStatefulWidget {
  const ParkingSearchBar({super.key});

  @override
  ConsumerState<ParkingSearchBar> createState() => _ParkingSearchBarState();
}

class _ParkingSearchBarState extends ConsumerState<ParkingSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _showError('Please enter a location to search');
      return;
    }

    setState(() => _isSearching = true);
    _searchFocusNode.unfocus();

    try {
      final searchService = ref.read(searchServiceProvider);
      final result = await searchService.searchLocation(query);

      if (!mounted) return;

      if (result == null) {
        _showError('Location not found. Try another search term.');
        setState(() => _isSearching = false);
        return;
      }

      // Convert search result to LocationData and update the searched location
      final locationData = searchService.toLocationData(result);
      ref.read(searchedLocationProvider.notifier).state = locationData;
      ref.read(searchQueryProvider.notifier).state = query;

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppConstants.spacing8),
                Expanded(
                  child: Text('Found parking near ${result.address}'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Search error: $e');
      _showError('Search failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: AppConstants.spacing8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchedLocationProvider.notifier).state = null;
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final hasSearchedLocation = ref.watch(searchedLocationProvider) != null;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main search input
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search for parking location...',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.ctaPrimary,
                size: 24,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clear button (shown when there's text)
                  if (_searchController.text.isNotEmpty || hasSearchedLocation)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                      tooltip: 'Clear search',
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
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _performSearch,
          ),

          // Active search indicator
          if (_isSearching)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing12,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaPrimary),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacing12),
                  Text(
                    'Searching for parking...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Current search location display
          if (hasSearchedLocation && !_isSearching && searchQuery.isNotEmpty)
            Container(
              padding: EdgeInsets.all(AppConstants.spacing12),
              decoration: BoxDecoration(
                color: AppColors.ctaPrimary.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppConstants.radius16),
                  bottomRight: Radius.circular(AppConstants.radius16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.ctaPrimary,
                    size: 16,
                  ),
                  SizedBox(width: AppConstants.spacing8),
                  Expanded(
                    child: Text(
                      'Showing parking near: $searchQuery',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),


        ],
      ),
    );
  }
}
