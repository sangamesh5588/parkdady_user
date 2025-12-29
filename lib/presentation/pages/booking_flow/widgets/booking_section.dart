import 'package:flutter/material.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../../domain/entities/parking_space.dart';

class BookingSection extends StatefulWidget {
  final ParkingSpace parkingSpace;
  final Function({
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) onDateTimeSelected;

  const BookingSection({
    super.key,
    required this.parkingSpace,
    required this.onDateTimeSelected,
  });

  @override
  State<BookingSection> createState() => _BookingSectionState();
}

class _BookingSectionState extends State<BookingSection> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    // Pre-fill with tomorrow's date and common time slots
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _startTime = const TimeOfDay(hour: 9, minute: 0); // 9 AM
    _endTime = const TimeOfDay(hour: 17, minute: 0); // 5 PM
    _notifyDateTimeChange();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
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
          // Enhanced section header
          Container(
            padding: EdgeInsets.all(AppConstants.spacing20),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radius16),
                topRight: Radius.circular(AppConstants.radius16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppConstants.spacing8),
                  decoration: BoxDecoration(
                    color: AppColors.ctaPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppColors.ctaPrimary,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppConstants.spacing12),
                Text(
                  'Select Date & Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
                const Spacer(),
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
                    'Flexible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Padding(
            padding: EdgeInsets.all(AppConstants.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker
                _buildEnhancedDatePicker(context),

                SizedBox(height: AppConstants.spacing20),

                // Time picker
                _buildEnhancedTimePicker(context),

                SizedBox(height: AppConstants.spacing20),

                // Duration and price preview
                if (_startTime != null && _endTime != null)
                  _buildEnhancedPricePreview(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.getPrimaryText(context),
          ),
        ),

        SizedBox(height: AppConstants.spacing8),

        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(AppConstants.radius8),
          child: Container(
            padding: EdgeInsets.all(AppConstants.spacing12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(AppConstants.radius8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.ctaPrimary,
                  size: 20,
                ),
                SizedBox(width: AppConstants.spacing12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null
                          ? AppColors.getPrimaryText(context)
                          : AppColors.getSecondaryText(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.getSecondaryText(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.getPrimaryText(context),
          ),
        ),

        SizedBox(height: AppConstants.spacing8),

        Row(
          children: [
            // Start time
            Expanded(
              child: InkWell(
                onTap: () => _selectStartTime(context),
                borderRadius: BorderRadius.circular(AppConstants.radius8),
                child: Container(
                  padding: EdgeInsets.all(AppConstants.spacing12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radius8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.ctaPrimary,
                        size: 20,
                      ),
                      SizedBox(width: AppConstants.spacing8),
                      Text(
                        _startTime != null
                            ? _startTime!.format(context)
                            : 'Start',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _startTime != null
                              ? AppColors.getPrimaryText(context)
                              : AppColors.getSecondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(width: AppConstants.spacing12),

            // End time
            Expanded(
              child: InkWell(
                onTap: () => _selectEndTime(context),
                borderRadius: BorderRadius.circular(AppConstants.radius8),
                child: Container(
                  padding: EdgeInsets.all(AppConstants.spacing12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radius8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.ctaPrimary,
                        size: 20,
                      ),
                      SizedBox(width: AppConstants.spacing8),
                      Text(
                        _endTime != null
                            ? _endTime!.format(context)
                            : 'End',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _endTime != null
                              ? AppColors.getPrimaryText(context)
                              : AppColors.getSecondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricePreview(BuildContext context) {
    final duration = _calculateDuration();
    final totalPrice = duration * widget.parkingSpace.pricePerHour;

    return Container(
      padding: EdgeInsets.all(AppConstants.spacing12),
      decoration: BoxDecoration(
        color: AppColors.ctaPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radius8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.ctaPrimary,
            size: 20,
          ),
          SizedBox(width: AppConstants.spacing8),
          Expanded(
            child: Text(
              '${duration.toStringAsFixed(1)} hours • \$${totalPrice.toStringAsFixed(2)} total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ctaPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _notifyDateTimeChange();
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
      _notifyDateTimeChange();
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
    );

    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
      _notifyDateTimeChange();
    }
  }

  void _notifyDateTimeChange() {
    widget.onDateTimeSelected(
      date: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
    );
  }

  double _calculateDuration() {
    if (_startTime == null || _endTime == null) return 0;

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    final durationMinutes = endMinutes - startMinutes;
    return durationMinutes / 60.0;
  }

  Widget _buildEnhancedDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event,
              size: 18,
              color: AppColors.ctaPrimary,
            ),
            SizedBox(width: AppConstants.spacing8),
            Text(
              'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimaryText(context),
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacing12),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          child: Container(
            padding: EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppConstants.radius12),
              border: Border.all(
                color: AppColors.divider,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppConstants.spacing8),
                  decoration: BoxDecoration(
                    color: AppColors.ctaPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radius8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppColors.ctaPrimary,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppConstants.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getSecondaryText(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing4),
                      Text(
                        _selectedDate != null
                            ? '${_getWeekdayName(_selectedDate!)}, ${_selectedDate!.day} ${_getMonthName(_selectedDate!)}'
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedDate != null
                              ? AppColors.getPrimaryText(context)
                              : AppColors.getSecondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.getSecondaryText(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTimePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 18,
              color: AppColors.ctaPrimary,
            ),
            SizedBox(width: AppConstants.spacing8),
            Text(
              'Select Time Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimaryText(context),
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacing12),
        Row(
          children: [
            // Start time
            Expanded(
              child: InkWell(
                onTap: () => _selectStartTime(context),
                borderRadius: BorderRadius.circular(AppConstants.radius12),
                child: Container(
                  padding: EdgeInsets.all(AppConstants.spacing16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                    border: Border.all(
                      color: AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppConstants.spacing8),
                        decoration: BoxDecoration(
                          color: AppColors.ctaPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radius8),
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: AppColors.ctaPrimary,
                          size: 16,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing8),
                      Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getSecondaryText(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing4),
                      Text(
                        _startTime != null ? _startTime!.format(context) : '--:--',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _startTime != null
                              ? AppColors.getPrimaryText(context)
                              : AppColors.getSecondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Arrow indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.spacing12),
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.getSecondaryText(context),
                size: 20,
              ),
            ),

            // End time
            Expanded(
              child: InkWell(
                onTap: () => _selectEndTime(context),
                borderRadius: BorderRadius.circular(AppConstants.radius12),
                child: Container(
                  padding: EdgeInsets.all(AppConstants.spacing16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                    border: Border.all(
                      color: AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppConstants.spacing8),
                        decoration: BoxDecoration(
                          color: AppColors.ctaPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radius8),
                        ),
                        child: Icon(
                          Icons.stop,
                          color: AppColors.ctaPrimary,
                          size: 16,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing8),
                      Text(
                        'End',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getSecondaryText(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing4),
                      Text(
                        _endTime != null ? _endTime!.format(context) : '--:--',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _endTime != null
                              ? AppColors.getPrimaryText(context)
                              : AppColors.getSecondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedPricePreview(BuildContext context) {
    final duration = _calculateDuration();
    final totalPrice = duration * widget.parkingSpace.pricePerHour;

    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.ctaPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: AppColors.ctaPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.ctaPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radius8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: AppColors.ctaPrimary,
                  size: 16,
                ),
              ),
              SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryText(context),
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing4),
                    Text(
                      '${duration.toStringAsFixed(1)} hours • \$${widget.parkingSpace.pricePerHour}/hr',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getSecondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ctaPrimary,
                    ),
                  ),
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getSecondaryText(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }
}
