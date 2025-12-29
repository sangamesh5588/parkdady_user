import 'package:flutter/material.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';

class ParkingInfoSection extends StatelessWidget {
  final String name;
  final String address;
  final double rating;
  final int reviewCount;

  const ParkingInfoSection({
    super.key,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: AppColors.ctaPrimary),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing12),
          Row(
            children: [
              Icon(Icons.star, size: 18, color: Colors.amber),
              SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                ' ($reviewCount reviews)',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
