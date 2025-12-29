import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../providers/parking_provider.dart';

class BookingSelectionScreen extends ConsumerStatefulWidget {
  final ParkingSpaceCard parkingSpace;

  const BookingSelectionScreen({
    super.key,
    required this.parkingSpace,
  });

  @override
  ConsumerState<BookingSelectionScreen> createState() => _BookingSelectionScreenState();
}

class _BookingSelectionScreenState extends ConsumerState<BookingSelectionScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedStartTime = TimeOfDay.now();
  int selectedDurationHours = 2;
  String? selectedVehicleType;

  final List<int> durationOptions = [1, 2, 3, 4, 6, 8, 12, 24];
  late List<String> vehicleTypes;

  @override
  void initState() {
    super.initState();
    // Get available vehicle types from parking space
    vehicleTypes = widget.parkingSpace.getAvailableVehicleTypes();
    // Set default to first available vehicle type
    selectedVehicleType = vehicleTypes.isNotEmpty ? vehicleTypes.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotalPrice();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('Book Parking'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parking Space Summary Card
            Container(
              margin: EdgeInsets.all(AppConstants.spacing16),
              padding: EdgeInsets.all(AppConstants.spacing16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radius16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                    child: widget.parkingSpace.images.isNotEmpty
                        ? Image.network(
                            widget.parkingSpace.images.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  SizedBox(width: AppConstants.spacing12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.parkingSpace.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                widget.parkingSpace.address,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 2),
                            Text(
                              widget.parkingSpace.averageRating?.toStringAsFixed(1) ?? '4.5',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '₹${widget.parkingSpace.pricePerHour}/hr',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ctaPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Date Selection
            _buildSection(
              title: 'Select Date',
              child: _buildDateSelector(),
            ),

            // Time Selection
            _buildSection(
              title: 'Select Start Time',
              child: _buildTimeSelector(),
            ),

            // Duration Selection
            _buildSection(
              title: 'Select Duration',
              child: _buildDurationSelector(),
            ),

            // Vehicle Type Selection
            _buildSection(
              title: 'Vehicle Type',
              child: _buildVehicleTypeSelector(),
            ),

            // Booking Summary
            Container(
              margin: EdgeInsets.all(AppConstants.spacing16),
              padding: EdgeInsets.all(AppConstants.spacing16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radius16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing16),

                  // Booking details in card format
                  Container(
                    padding: EdgeInsets.all(AppConstants.spacing12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(AppConstants.radius12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Date', DateFormat('dd MMM yyyy').format(selectedDate)),
                        SizedBox(height: 4),
                        _buildSummaryRow('Start Time', _formatTimeOfDay(selectedStartTime)),
                        SizedBox(height: 4),
                        _buildSummaryRow('End Time', _formatTimeOfDay(_calculateEndTime())),
                        SizedBox(height: 4),
                        _buildSummaryRow('Duration', '$selectedDurationHours ${selectedDurationHours == 1 ? 'hour' : 'hours'}'),
                        SizedBox(height: 4),
                        _buildSummaryRow('Vehicle Type', selectedVehicleType ?? 'Not selected'),
                      ],
                    ),
                  ),

                  SizedBox(height: AppConstants.spacing16),
                  Divider(height: 1, color: AppColors.divider),
                  SizedBox(height: AppConstants.spacing16),

                  // Price breakdown
                  if (widget.parkingSpace.hasDiscount) ...[
                    Container(
                      padding: EdgeInsets.all(AppConstants.spacing12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(AppConstants.radius8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer, size: 18, color: Colors.green.shade700),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Special discount applied to this booking!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing12),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rate',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _getPriceDisplay(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$selectedDurationHours ${selectedDurationHours == 1 ? 'hour' : 'hours'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppConstants.spacing16),
                  Divider(height: 1, color: AppColors.divider, thickness: 2),
                  SizedBox(height: AppConstants.spacing16),

                  // Total amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '₹${totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: widget.parkingSpace.hasDiscount
                            ? Colors.green.shade700
                            : AppColors.ctaPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Payment Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
              padding: EdgeInsets.all(AppConstants.spacing20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radius16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing8),
                  Text(
                    'You will be redirected to secure payment gateway',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing20),

                  // Continue to Payment Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceedToConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaPrimary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radius12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Continue to Payment',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppConstants.spacing12),

                  // Security info
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Text(
                          'Secure payment • Free cancellation available',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppConstants.spacing24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing8,
      ),
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing12),
          child,
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.all(AppConstants.spacing12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppConstants.radius12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.ctaPrimary),
            SizedBox(width: AppConstants.spacing12),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(selectedDate),
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: EdgeInsets.all(AppConstants.spacing12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppConstants.radius12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.ctaPrimary),
            SizedBox(width: AppConstants.spacing12),
            Text(
              _formatTimeOfDay(selectedStartTime),
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Wrap(
      spacing: AppConstants.spacing8,
      runSpacing: AppConstants.spacing8,
      children: durationOptions.map((hours) {
        final isSelected = selectedDurationHours == hours;
        return InkWell(
          onTap: () {
            setState(() {
              selectedDurationHours = hours;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.ctaPrimary : Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radius12),
              border: Border.all(
                color: isSelected ? AppColors.ctaPrimary : AppColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              hours == 24 ? '1 Day' : '$hours ${hours == 1 ? 'hr' : 'hrs'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVehicleTypeSelector() {
    return Row(
      children: vehicleTypes.map((type) {
        final isSelected = selectedVehicleType == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: type != vehicleTypes.last ? 8 : 0),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedVehicleType = type;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ctaPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                  border: Border.all(
                    color: isSelected ? AppColors.ctaPrimary : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getVehicleIcon(type),
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      size: 24,
                    ),
                    SizedBox(height: 6),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
      ),
      child: Icon(
        Icons.local_parking,
        color: AppColors.textMuted,
        size: 32,
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'Car':
        return Icons.directions_car;
      case 'Bike':
        return Icons.two_wheeler;
      case 'SUV':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay _calculateEndTime() {
    final startMinutes = selectedStartTime.hour * 60 + selectedStartTime.minute;
    final endMinutes = startMinutes + (selectedDurationHours * 60);
    return TimeOfDay(hour: (endMinutes ~/ 60) % 24, minute: endMinutes % 60);
  }

  String _getPriceDisplay() {
    if (selectedVehicleType == null) return '₹0';

    final isDailyBooking = selectedDurationHours >= 24;
    double rate = 0;
    String unit = '/hour';

    if (selectedVehicleType == 'Car') {
      if (isDailyBooking && widget.parkingSpace.dailyRateCar != null) {
        rate = widget.parkingSpace.dailyRateCar!;
        unit = '/day';
      } else {
        rate = widget.parkingSpace.hourlyRateCar ?? 0;
      }
    } else if (selectedVehicleType == 'Bike') {
      if (isDailyBooking && widget.parkingSpace.dailyRateBike != null) {
        rate = widget.parkingSpace.dailyRateBike!;
        unit = '/day';
      } else {
        rate = widget.parkingSpace.hourlyRateBike ?? 0;
      }
    }

    return '₹${rate.toStringAsFixed(2)}$unit';
  }

  double _calculateTotalPrice() {
    if (selectedVehicleType == null) return 0;

    double pricePerHour = 0;

    // Determine if we should use daily rate (24 hours = 1 day)
    final isDailyBooking = selectedDurationHours >= 24;

    if (selectedVehicleType == 'Car') {
      if (isDailyBooking && widget.parkingSpace.dailyRateCar != null) {
        // Use daily rate for car
        final dailyRate = widget.parkingSpace.dailyRateCar!;
        return dailyRate * (selectedDurationHours / 24);
      } else {
        // Use hourly rate
        pricePerHour = widget.parkingSpace.hourlyRateCar ?? 0;
      }
    } else if (selectedVehicleType == 'Bike') {
      if (isDailyBooking && widget.parkingSpace.dailyRateBike != null) {
        // Use daily rate for bike
        final dailyRate = widget.parkingSpace.dailyRateBike!;
        return dailyRate * (selectedDurationHours / 24);
      } else {
        // Use hourly rate
        pricePerHour = widget.parkingSpace.hourlyRateBike ?? 0;
      }
    }

    return pricePerHour * selectedDurationHours;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.ctaPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    // Calculate minimum allowed time (current time + 30 minutes buffer)
    TimeOfDay initialTime = selectedStartTime;
    if (isToday) {
      final minimumTime = TimeOfDay(
        hour: now.hour,
        minute: now.minute + 30, // 30 minute buffer
      );

      // If current selection is in the past, use minimum time
      final selectedMinutes = selectedStartTime.hour * 60 + selectedStartTime.minute;
      final minimumMinutes = minimumTime.hour * 60 + minimumTime.minute;

      if (selectedMinutes < minimumMinutes) {
        initialTime = minimumTime;
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.dial, // Use dial/scroll picker
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.ctaPrimary,
            ),
            timePickerTheme: TimePickerThemeData(
              dialHandColor: AppColors.ctaPrimary,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate that picked time is not in the past (if today)
      if (isToday) {
        final pickedMinutes = picked.hour * 60 + picked.minute;
        final currentMinutes = now.hour * 60 + now.minute + 30; // 30 minute buffer

        if (pickedMinutes < currentMinutes) {
          // Show error - time is in the past
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please select a time at least 30 minutes from now',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return; // Don't update the time
        }
      }

      // Time is valid, update it
      if (picked != selectedStartTime) {
        setState(() {
          selectedStartTime = picked;
        });
      }
    }
  }

  void _proceedToConfirmation() {
    final bookingData = {
      'parkingSpace': widget.parkingSpace,
      'date': selectedDate,
      'startTime': selectedStartTime,
      'duration': selectedDurationHours,
      'vehicleType': selectedVehicleType,
      'totalPrice': _calculateTotalPrice(),
    };

    Navigator.pushNamed(
      context,
      '/booking-confirmation',
      arguments: bookingData,
    );
  }
}
