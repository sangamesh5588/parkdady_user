import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import 'widgets/active_bookings_list.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: _buildWhiteHeader(context),
      body: _buildActiveBookingsTab(),
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

  Widget _buildActiveBookingsTab() {
    return Container(
      color: AppColors.primaryBackground,
      child: const ActiveBookingsList(),
    );
  }
}
