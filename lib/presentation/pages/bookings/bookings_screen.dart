import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import 'widgets/active_bookings_list.dart';
import 'widgets/past_bookings_list.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: _buildWhiteHeader(context),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(context),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active bookings tab
                _buildActiveBookingsTab(),
                // Past bookings tab
                _buildPastBookingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildWhiteHeader(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'My Bookings',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.getPrimaryText(context),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
      child: Text(
        'My Bookings',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.getPrimaryText(context),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.ctaPrimary,
          borderRadius: BorderRadius.circular(AppConstants.radius8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.getButtonPrimaryText(context),
        unselectedLabelColor: AppColors.getSecondaryText(context),
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.all(4),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_parking, size: 18),
                SizedBox(width: AppConstants.spacing8),
                Text('Active'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 18),
                SizedBox(width: AppConstants.spacing8),
                Text('Past'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBookingsTab() {
    return Container(
      color: AppColors.primaryBackground,
      child: const ActiveBookingsList(),
    );
  }

  Widget _buildPastBookingsTab() {
    return Container(
      color: AppColors.primaryBackground,
      child: const PastBookingsList(),
    );
  }

  void _showNotifications(BuildContext context) {
    // TODO: Show notifications modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifications coming soon'),
        backgroundColor: AppColors.ctaPrimary,
      ),
    );
  }
}
