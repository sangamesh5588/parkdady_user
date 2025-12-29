import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../providers/parking_provider.dart';
import '../../parking_details/parking_details_screen.dart';

class SearchParkingCardWidget extends ConsumerStatefulWidget {
  final ParkingSpaceCard card;

  const SearchParkingCardWidget({
    super.key,
    required this.card,
  });

  @override
  ConsumerState<SearchParkingCardWidget> createState() => _SearchParkingCardWidgetState();
}

class _SearchParkingCardWidgetState extends ConsumerState<SearchParkingCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16, vertical: AppConstants.spacing8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          onTap: () => _navigateToDetails(context),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image and basic info row
                Row(
                  children: [
                    // Image
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.radius8),
                        child: _buildImage(),
                      ),
                    ),
                    SizedBox(width: AppConstants.spacing12),

                    // Basic info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.card.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppConstants.spacing4),

                          // Address
                          Text(
                            widget.card.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppConstants.spacing12),

                // Price and rating row
                Row(
                  children: [
                    // Price
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing8,
                        vertical: AppConstants.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ctaPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radius4),
                      ),
                      child: Text(
                        '₹${_getLowestPrice().toStringAsFixed(0)}/hr',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ctaPrimary,
                        ),
                      ),
                    ),

                    SizedBox(width: AppConstants.spacing8),

                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 2),
                        Text(
                          widget.card.averageRating?.toStringAsFixed(1) ?? '4.5',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    Spacer(),

                    // Distance
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 2),
                        Text(
                          widget.card.formattedDistance,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Features row (if any)
                if (widget.card.features.isNotEmpty) ...[
                  SizedBox(height: AppConstants.spacing8),
                  Wrap(
                    spacing: AppConstants.spacing4,
                    runSpacing: AppConstants.spacing4,
                    children: widget.card.features.take(3).map((feature) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacing8,
                          vertical: AppConstants.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(AppConstants.radius12),
                        ),
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Discount badge (if applicable)
                if (widget.card.hasDiscount) ...[
                  SizedBox(height: AppConstants.spacing8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_getDiscountPercent().toStringAsFixed(0)}% OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.card.images.isEmpty) {
      return Container(
        color: AppColors.secondaryBackground,
        child: Center(
          child: Icon(
            Icons.local_parking,
            size: 32,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return Image.network(
      widget.card.images.first,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.secondaryBackground,
        child: Center(
          child: Icon(
            Icons.local_parking,
            size: 32,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  double _getLowestPrice() {
    // Get the lowest price between car and bike (hourly rates)
    final carPrice = widget.card.hourlyRateCar ?? 0;
    final bikePrice = widget.card.hourlyRateBike ?? 0;

    if (carPrice > 0 && bikePrice > 0) {
      return carPrice < bikePrice ? carPrice : bikePrice;
    } else if (carPrice > 0) {
      return carPrice;
    } else if (bikePrice > 0) {
      return bikePrice;
    }
    return widget.card.pricePerHour;
  }

  double _getDiscountPercent() {
    // No discounts - always return 0
    return 0;
  }

  void _navigateToDetails(BuildContext context) {
    // Ensure proper navigation to parking details
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParkingDetailsScreen(parkingSpace: widget.card),
        settings: RouteSettings(name: '/parking-details'),
      ),
    );
  }
}
