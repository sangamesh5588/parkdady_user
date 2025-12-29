import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../providers/parking_provider.dart';
import '../../parking_details/parking_details_screen.dart';

class ParkingSpaceCardWidget extends ConsumerStatefulWidget {
  final ParkingSpaceCard card;

  const ParkingSpaceCardWidget({
    super.key,
    required this.card,
  });

  @override
  ConsumerState<ParkingSpaceCardWidget> createState() => _ParkingSpaceCardWidgetState();
}

class _ParkingSpaceCardWidgetState extends ConsumerState<ParkingSpaceCardWidget> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16, vertical: AppConstants.spacing8),
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.secondaryBackground.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radius20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 20,
            offset: const Offset(-4, -4),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radius20),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radius20),
          onTap: () => _navigateToDetails(context),
          splashColor: AppColors.ctaPrimary.withOpacity(0.1),
          highlightColor: AppColors.ctaPrimary.withOpacity(0.05),
          child: Row(
            children: [
              // Image section
              SizedBox(
                width: 140,
                child: Stack(
                  children: [
                    _buildCompactImage(),
                    // Badge overlay
                    if (widget.card.features.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildBadge(widget.card.features.first),
                      ),
                  ],
                ),
              ),

              // Content section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.card.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppConstants.spacing4),

                          // Description
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

                      // Bottom section - Price and info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price with discount styling
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Show discounted price if available
                                  if (widget.card.hasDiscount) ...[
                                    Text(
                                      '₹${_getLowestPrice().toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    Text(
                                      '₹${widget.card.pricePerHour.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMuted,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      '₹${widget.card.pricePerHour.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ctaPrimary,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(width: 4),
                              Padding(
                                padding: EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '/hr',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (widget.card.hasDiscount) ...[
                                SizedBox(width: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                              Spacer(),
                              // Rating
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
                          SizedBox(height: AppConstants.spacing4),

                          // Distance and vehicle type
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
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
                              SizedBox(width: AppConstants.spacing8),
                              Icon(
                                Icons.directions_car,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Car/Bike',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactImage() {
    if (widget.card.images.isEmpty) {
      return _buildImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.horizontal(left: Radius.circular(AppConstants.radius20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.ctaPrimary.withOpacity(0.1),
              AppColors.ctaPrimary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Image.network(
          widget.card.images.first,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(AppConstants.radius20)),
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryBackground,
            AppColors.secondaryBackground.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.spacing8),
              decoration: BoxDecoration(
                color: AppColors.ctaPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radius12),
              ),
              child: Icon(
                Icons.local_parking,
                size: 32,
                color: AppColors.ctaPrimary.withOpacity(0.7),
              ),
            ),
            SizedBox(height: AppConstants.spacing4),
            Text(
              'No Image',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingDetailsScreen(parkingSpace: widget.card),
      ),
    );
  }
}
