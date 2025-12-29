import 'package:flutter/material.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../../domain/entities/parking_space.dart';

class SpaceInfoSection extends StatelessWidget {
  final ParkingSpace parkingSpace;

  const SpaceInfoSection({
    super.key,
    required this.parkingSpace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced title and rating section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with better typography
                    Text(
                      parkingSpace.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getPrimaryText(context),
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing8),
                    // Enhanced address with icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppConstants.spacing8),
                          decoration: BoxDecoration(
                            color: AppColors.ctaPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.radius8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.ctaPrimary,
                          ),
                        ),
                        SizedBox(width: AppConstants.spacing8),
                        Expanded(
                          child: Text(
                            parkingSpace.address,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.getSecondaryText(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppConstants.spacing16),
              // Enhanced rating badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing12,
                  vertical: AppConstants.spacing8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radius16),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Colors.amber[700],
                    ),
                    SizedBox(width: AppConstants.spacing8),
                    Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber[700],
                      ),
                    ),
                    Text(
                      ' (127)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getSecondaryText(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing20),

          // Enhanced description with better styling
          Container(
            padding: EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppConstants.radius12),
              border: Border.all(
                color: AppColors.divider,
                width: 0.5,
              ),
            ),
            child: Text(
              parkingSpace.description.isNotEmpty
                  ? parkingSpace.description
                  : 'A convenient parking space perfect for your vehicle needs. Secure, well-maintained, and easily accessible.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getPrimaryText(context),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          SizedBox(height: AppConstants.spacing24),

          // Enhanced amenities section
          _buildEnhancedAmenitiesSection(context),

          SizedBox(height: AppConstants.spacing24),

          // Enhanced parking details
          _buildEnhancedParkingDetails(context),
        ],
      ),
    );
  }

  Widget _buildEnhancedAmenitiesSection(BuildContext context) {
    // TODO: Add actual amenities from database
    final amenities = ['Covered', 'Security Cameras', '24/7 Access'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Amenities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.getPrimaryText(context),
              ),
            ),
            SizedBox(width: AppConstants.spacing8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing8,
                vertical: AppConstants.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.statusSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radius12),
              ),
              child: Text(
                'Premium Features',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusSuccess,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacing16),
        Wrap(
          spacing: AppConstants.spacing12,
          runSpacing: AppConstants.spacing12,
          children: amenities.map((amenity) => _buildEnhancedAmenityChip(context, amenity)).toList(),
        ),
      ],
    );
  }

  Widget _buildEnhancedAmenityChip(BuildContext context, String amenity) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: AppColors.ctaPrimary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ctaPrimary.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacing8),
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radius12),
            ),
            child: Icon(
              _getAmenityIcon(amenity),
              size: 16,
              color: AppColors.ctaPrimary,
            ),
          ),
          SizedBox(width: AppConstants.spacing8),
          Text(
            amenity,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ctaPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(BuildContext context, String amenity) {
    return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacing12,
          vertical: AppConstants.spacing4,
        ),
      decoration: BoxDecoration(
        color: AppColors.ctaPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: AppColors.ctaPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAmenityIcon(amenity),
            size: 16,
            color: AppColors.ctaPrimary,
          ),
          SizedBox(width: AppConstants.spacing4),
          Text(
            amenity,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.ctaPrimary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'covered':
        return Icons.home;
      case 'security cameras':
        return Icons.videocam;
      case '24/7 access':
        return Icons.access_time;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildParkingDetails(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            context,
            'Total Spots',
            parkingSpace.totalSpots.toString(),
            Icons.local_parking,
          ),
          SizedBox(height: AppConstants.spacing12),
          _buildDetailRow(
            context,
            'Available Spots',
            parkingSpace.availableSpots.toString(),
            Icons.check_circle,
          ),
          SizedBox(height: AppConstants.spacing12),
          _buildDetailRow(
            context,
            'Price per Hour',
            '\$${parkingSpace.pricePerHour.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedParkingDetails(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Parking Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getPrimaryText(context),
                ),
              ),
              SizedBox(width: AppConstants.spacing8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing8,
                  vertical: AppConstants.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppColors.statusSuccess,
                    ),
                    SizedBox(width: AppConstants.spacing4),
                    Text(
                      'Available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusSuccess,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing20),
          _buildEnhancedDetailRow(
            context,
            'Total Spots',
            parkingSpace.totalSpots.toString(),
            Icons.local_parking,
          ),
          SizedBox(height: AppConstants.spacing16),
          _buildEnhancedDetailRow(
            context,
            'Available Spots',
            parkingSpace.availableSpots.toString(),
            Icons.check_circle,
          ),
          SizedBox(height: AppConstants.spacing16),
          _buildEnhancedDetailRow(
            context,
            'Price per Hour',
            '\$${parkingSpace.pricePerHour.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing12),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radius12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.ctaPrimary,
            ),
          ),
          SizedBox(width: AppConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getSecondaryText(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppConstants.spacing4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.ctaPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radius4),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.ctaPrimary,
          ),
        ),
        SizedBox(width: AppConstants.spacing12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getSecondaryText(context),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getPrimaryText(context),
          ),
        ),
      ],
    );
  }
}
