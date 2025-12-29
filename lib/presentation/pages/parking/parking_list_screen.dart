import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../providers/parking_provider.dart';
import '../../../domain/entities/parking_spot.dart';

class ParkingListScreen extends ConsumerWidget {
  const ParkingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parkingState = ref.watch(parkingProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Available Parking',
          style: TextStyle(color: AppColors.getPrimaryText(context)),
        ),
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 2,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(parkingProvider.notifier).refresh(),
          ),
          // Last updated indicator
          if (parkingState.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Center(
                child: Text(
                  'Updated: ${DateFormat('HH:mm').format(parkingState.lastUpdated!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getSecondaryText(context),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: parkingState.isLoading
          ? _buildLoadingState()
          : parkingState.error != null
              ? _buildErrorState(context, parkingState.error!, ref)
              : parkingState.spots.isEmpty
                  ? _buildEmptyState(context)
                  : _buildParkingList(context, parkingState.spots),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading parking data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load parking data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.getSecondaryText(context)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(parkingProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_parking,
            size: 64,
            color: AppColors.getSecondaryText(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No parking slots available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for updates',
            style: TextStyle(color: AppColors.getSecondaryText(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingList(BuildContext context, List<ParkingSpot> spots) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh is handled by provider
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: spots.length,
        itemBuilder: (context, index) {
          final spot = spots[index];
          final isToday = _isToday(spot.date);

          return _ParkingSpotCard(
            spot: spot,
            isToday: isToday,
          );
        },
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _ParkingSpotCard extends StatelessWidget {
  final ParkingSpot spot;
  final bool isToday;

  const _ParkingSpotCard({
    required this.spot,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isToday ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        side: isToday
            ? BorderSide(color: AppColors.ctaPrimary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: isToday ? AppColors.ctaPrimary : colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM d, y').format(spot.date),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isToday ? AppColors.ctaPrimary : colorScheme.onSurface,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.ctaPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getButtonPrimaryText(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Availability Info
            Row(
              children: [
                // Car Slots
                Expanded(
                  child: _AvailabilityChip(
                    icon: Icons.directions_car,
                    label: 'Car Slots',
                    count: spot.activeCarSlots,
                    color: spot.activeCarSlots > 0 ? Colors.green : Colors.grey,
                  ),
                ),

                const SizedBox(width: 12),

                // Bike Slots
                Expanded(
                  child: _AvailabilityChip(
                    icon: Icons.two_wheeler,
                    label: 'Bike Slots',
                    count: spot.activeBikeSlots,
                    color: spot.activeBikeSlots > 0 ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),

            // Book Button (if available)
            if (spot.hasAvailability) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to booking screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking feature coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      color: AppColors.getButtonPrimaryText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _AvailabilityChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
