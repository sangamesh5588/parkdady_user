import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../providers/parking_provider.dart';

class QuickFiltersRow extends ConsumerWidget {
  const QuickFiltersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(homeSearchFiltersProvider);

    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16).copyWith(top: AppConstants.spacing12, bottom: AppConstants.spacing8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Nearest',
            icon: Icons.near_me,
            filterKey: 'nearest',
            isSelected: filters.selectedFilters.contains('nearest'),
          ),
          SizedBox(width: AppConstants.spacing4),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Cheapest',
            icon: Icons.currency_rupee,
            filterKey: 'cheapest',
            isSelected: filters.selectedFilters.contains('cheapest'),
          ),
          SizedBox(width: AppConstants.spacing4),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Covered',
            icon: Icons.roofing,
            filterKey: 'covered',
            isSelected: filters.selectedFilters.contains('covered'),
          ),
          SizedBox(width: AppConstants.spacing4),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'EV',
            icon: Icons.ev_station,
            filterKey: 'ev',
            isSelected: filters.selectedFilters.contains('ev'),
          ),
          SizedBox(width: AppConstants.spacing4),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: '24x7',
            icon: Icons.access_time,
            filterKey: '24x7',
            isSelected: filters.selectedFilters.contains('24x7'),
          ),
          SizedBox(width: AppConstants.spacing4),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Bike',
            icon: Icons.pedal_bike,
            filterKey: 'bike',
            isSelected: filters.selectedFilters.contains('bike'),
          ),
          SizedBox(width: AppConstants.spacing4),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Car',
            icon: Icons.directions_car,
            filterKey: 'car',
            isSelected: filters.selectedFilters.contains('car'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required String filterKey,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, isSelected ? -2 : 0, 0),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing4),
        child: Material(
          elevation: isSelected ? 8 : 2,
          shadowColor: isSelected
              ? Colors.black.withOpacity(0.4)
              : Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radius20),
          child: InkWell(
            onTap: () => _toggleFilter(ref, filterKey, !isSelected),
            borderRadius: BorderRadius.circular(AppConstants.radius20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing8,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          Colors.grey.shade900,
                          Colors.black,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white,
                          AppColors.secondaryBackground,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(AppConstants.radius20),
                border: Border.all(
                  color: isSelected
                      ? Colors.grey.shade800
                      : AppColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      key: ValueKey('${icon}_${isSelected}'),
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.ctaPrimary,
                    ),
                  ),
                  SizedBox(width: AppConstants.spacing4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: isSelected ? 0.5 : 0,
                    ),
                    child: Text(label),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: AppConstants.spacing4),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFilter(WidgetRef ref, String filterKey, bool selected) {
    final currentFilters = ref.read(homeSearchFiltersProvider);
    final currentSelectedFilters = List<String>.from(currentFilters.selectedFilters);

    if (selected) {
      // Special handling for sorting filters (only one can be active)
      if (filterKey == 'nearest' || filterKey == 'cheapest') {
        currentSelectedFilters.removeWhere((f) => f == 'nearest' || f == 'cheapest');
      }
      currentSelectedFilters.add(filterKey);
    } else {
      currentSelectedFilters.remove(filterKey);
    }

    ref.read(homeSearchFiltersProvider.notifier).state =
        currentFilters.copyWith(selectedFilters: currentSelectedFilters);

    // Trigger a refresh of the parking spaces with new filters
    // The HomeParkingNotifier will automatically reload when filters change
  }
}
