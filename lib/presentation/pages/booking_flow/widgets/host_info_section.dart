import 'package:flutter/material.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../../domain/entities/parking_space.dart';

class HostInfoSection extends StatelessWidget {
  final ParkingSpace parkingSpace;

  const HostInfoSection({
    super.key,
    required this.parkingSpace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Host header
          Row(
            children: [
              // Host avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.ctaPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.getButtonPrimaryText(context),
                  size: 24,
                ),
              ),

              SizedBox(width: AppConstants.spacing12),

              // Host info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hosted by John', // TODO: Get actual host name
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryText(context),
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing4),
                    Text(
                      'Parking host since 2023', // TODO: Get actual host info
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getSecondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Contact button
              IconButton(
                onPressed: () {
                  // TODO: Implement contact host
                },
                icon: Icon(
                  Icons.message,
                  color: AppColors.ctaPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing16),

          // Host stats
          Row(
            children: [
              _buildHostStat(context, '4.9', 'Rating'),
              SizedBox(width: AppConstants.spacing24),
              _buildHostStat(context, '127', 'Reviews'),
              SizedBox(width: AppConstants.spacing24),
              _buildHostStat(context, '2', 'Years'),
            ],
          ),

          SizedBox(height: AppConstants.spacing16),

          // Host description
          Text(
            'Professional parking management with 24/7 customer support. All spaces are regularly inspected and maintained.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getPrimaryText(context),
              height: 1.4,
            ),
          ),

          SizedBox(height: AppConstants.spacing16),

          // Response rate
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 16,
                color: Colors.green,
              ),
              SizedBox(width: AppConstants.spacing4),
              Text(
                'Responds within 30 minutes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHostStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.getPrimaryText(context),
          ),
        ),
        SizedBox(height: AppConstants.spacing4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getSecondaryText(context),
          ),
        ),
      ],
    );
  }
}
