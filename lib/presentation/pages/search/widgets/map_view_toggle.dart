import 'package:flutter/material.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';

class MapViewToggle extends StatelessWidget {
  final bool showMap;
  final ValueChanged<bool> onToggle;

  const MapViewToggle({
    super.key,
    required this.showMap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing8,
      ),
      child: Row(
        children: [
          // List View Button
          Expanded(
            child: _buildToggleButton(
              context: context,
              icon: Icons.list,
              label: 'List',
              isSelected: !showMap,
              onTap: () => onToggle(false),
            ),
          ),

          SizedBox(width: AppConstants.spacing8),

          // Map View Button
          Expanded(
            child: _buildToggleButton(
              context: context,
              icon: Icons.map,
              label: 'Map',
              isSelected: showMap,
              onTap: () => onToggle(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? AppColors.ctaPrimary
          : AppColors.getSurfaceColor(context),
      borderRadius: BorderRadius.circular(AppConstants.radius8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius8),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppConstants.spacing12,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? AppColors.ctaPrimary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radius8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.getButtonPrimaryText(context)
                    : AppColors.getSecondaryText(context),
              ),
              SizedBox(width: AppConstants.spacing8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.getButtonPrimaryText(context)
                      : AppColors.getPrimaryText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
