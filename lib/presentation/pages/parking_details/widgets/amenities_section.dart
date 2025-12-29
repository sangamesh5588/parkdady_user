import 'package:flutter/material.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';

class AmenitiesSection extends StatelessWidget {
  final List<String> amenities;

  const AmenitiesSection({
    super.key,
    required this.amenities,
  });

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: AppConstants.spacing12),
      padding: EdgeInsets.all(AppConstants.spacing16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing16),
          Wrap(
            spacing: AppConstants.spacing12,
            runSpacing: AppConstants.spacing12,
            children: amenities.map((amenity) => _buildAmenityChip(amenity)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(String label) {
    final lowerLabel = label.toLowerCase().trim();
    IconData icon;

    // Map amenities to appropriate icons
    if (lowerLabel.contains('covered') || lowerLabel.contains('roofed')) {
      icon = Icons.roofing;
    } else if (lowerLabel.contains('cctv') || lowerLabel.contains('camera') || lowerLabel.contains('surveillance')) {
      icon = Icons.videocam;
    } else if (lowerLabel.contains('security') || lowerLabel.contains('guard')) {
      icon = Icons.security;
    } else if (lowerLabel.contains('ev') || lowerLabel.contains('electric') || lowerLabel.contains('charging')) {
      icon = Icons.ev_station;
    } else if (lowerLabel.contains('24') || lowerLabel.contains('24x7') || lowerLabel.contains('24/7')) {
      icon = Icons.access_time;
    } else if (lowerLabel.contains('valet')) {
      icon = Icons.local_parking;
    } else if (lowerLabel.contains('wash') || lowerLabel.contains('cleaning')) {
      icon = Icons.local_car_wash;
    } else if (lowerLabel.contains('wifi') || lowerLabel.contains('internet')) {
      icon = Icons.wifi;
    } else if (lowerLabel.contains('lighting') || lowerLabel.contains('light')) {
      icon = Icons.light_mode;
    } else if (lowerLabel.contains('restroom') || lowerLabel.contains('toilet') || lowerLabel.contains('washroom')) {
      icon = Icons.wc;
    } else if (lowerLabel.contains('disabled') || lowerLabel.contains('wheelchair') || lowerLabel.contains('accessible')) {
      icon = Icons.accessible;
    } else if (lowerLabel.contains('payment') || lowerLabel.contains('card') || lowerLabel.contains('digital')) {
      icon = Icons.payment;
    } else if (lowerLabel.contains('attended') || lowerLabel.contains('staff')) {
      icon = Icons.person;
    } else {
      icon = Icons.check_circle;
    }

    // Format label for display
    String displayLabel = label;
    if (lowerLabel == 'cctv') {
      displayLabel = 'CCTV';
    } else if (lowerLabel == 'ev' || lowerLabel == 'ev_charging') {
      displayLabel = 'EV Charging';
    } else if (lowerLabel == '24x7' || lowerLabel == '24/7') {
      displayLabel = '24x7 Access';
    } else if (label.contains('_')) {
      // Convert snake_case to Title Case
      displayLabel = label.split('_').map((word) =>
        word[0].toUpperCase() + word.substring(1).toLowerCase()
      ).join(' ');
    } else if (label == label.toLowerCase()) {
      // Capitalize first letter if all lowercase
      displayLabel = label[0].toUpperCase() + label.substring(1);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.ctaPrimary),
          SizedBox(width: 6),
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
