import 'package:flutter/material.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';

class SearchFilters extends StatefulWidget {
  const SearchFilters({super.key});

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  RangeValues _priceRange = const RangeValues(0, 50);
  String _duration = 'hourly';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration selector
          Text(
            'Duration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          Row(
            children: [
              _buildDurationChip('Hourly'),
              SizedBox(width: AppConstants.spacing8),
              _buildDurationChip('Daily'),
              SizedBox(width: AppConstants.spacing8),
              _buildDurationChip('Monthly'),
            ],
          ),

          SizedBox(height: AppConstants.spacing16),

          // Price range
          Text(
            'Price Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 50,
            divisions: 50,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
            activeColor: AppColors.ctaPrimary,
          ),

          // Amenities
          SizedBox(height: AppConstants.spacing16),
          Text(
            'Amenities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          Wrap(
            spacing: AppConstants.spacing8,
            runSpacing: AppConstants.spacing8,
            children: [
              _buildAmenityChip('Covered'),
              _buildAmenityChip('EV Charging'),
              _buildAmenityChip('Valet'),
              _buildAmenityChip('Security'),
              _buildAmenityChip('CCTV'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(String label) {
    final isSelected = _duration.toLowerCase() == label.toLowerCase();
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _duration = label.toLowerCase();
        });
      },
      backgroundColor: AppColors.getSurfaceColor(context),
      selectedColor: AppColors.ctaPrimary.withOpacity(0.1),
      checkmarkColor: AppColors.ctaPrimary,
    );
  }

  Widget _buildAmenityChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: false, // TODO: Implement selection logic
      onSelected: (selected) {
        // TODO: Implement amenity filtering
      },
      backgroundColor: AppColors.getSurfaceColor(context),
      selectedColor: AppColors.ctaPrimary.withOpacity(0.1),
      checkmarkColor: AppColors.ctaPrimary,
    );
  }
}
