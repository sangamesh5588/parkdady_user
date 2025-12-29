import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../core/qr_service.dart';

/// Booking Service
/// Handles user booking operations with Supabase
class BookingService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Calculate discounted price for booking
  /// Returns the final amount after applying discounts
  static double calculateDiscountedPrice({
    required String vehicleType,
    required bool isHourly,
    required int duration, // hours or days
    required double baseRate,
    double? discountAmount,
    double? discountPercent,
  }) {
    // Calculate total before discount
    final totalBeforeDiscount = baseRate * duration;

    // Apply discount if available
    double discountValue = 0;

    // Discount amount takes precedence over percentage
    if (discountAmount != null && discountAmount > 0) {
      discountValue = discountAmount * duration;
    } else if (discountPercent != null && discountPercent > 0) {
      discountValue = (totalBeforeDiscount * discountPercent) / 100;
    }

    final finalAmount = totalBeforeDiscount - discountValue;
    return finalAmount > 0 ? finalAmount : totalBeforeDiscount;
  }

  /// Create a new booking
  Future<Booking> createBooking({
    required String listingId,
    required String hostId,
    required String vehicleType, // 'car' or 'bike'
    required DateTime bookingDate,
    required TimeOfDay entryTime,
    required TimeOfDay exitTime,
    required int durationHours,
    required double baseAmount,
    String? paymentMethod,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final userEmail = _supabase.auth.currentUser?.email;

    try {

      debugPrint('🔐 Current user: $userEmail (ID: $userId)');

      if (userId == null) {
        debugPrint('❌ ERROR: User not authenticated - cannot create booking');
        throw Exception('User not authenticated. Please log in to create a booking.');
      }

      debugPrint('📝 Creating booking for listing: $listingId');
      debugPrint('📝 Booking details:');
      debugPrint('   - Renter ID: $userId');
      debugPrint('   - Host ID: $hostId');
      debugPrint('   - Vehicle: $vehicleType');
      debugPrint('   - Date: ${bookingDate.toIso8601String().split('T')[0]}');
      debugPrint('   - Time: ${entryTime.hour}:${entryTime.minute} - ${exitTime.hour}:${exitTime.minute}');
      debugPrint('   - Amount: ₹$baseAmount');

      // First insert the booking to get the booking ID
      final response = await _supabase
          .from('bookings')
          .insert({
            'listing_id': listingId,
            'renter_id': userId,
            'host_id': hostId,
            'vehicle_type': vehicleType.toLowerCase(),
            'booking_date': bookingDate.toIso8601String().split('T')[0], // YYYY-MM-DD
            'requested_entry_time': '${entryTime.hour.toString().padLeft(2, '0')}:${entryTime.minute.toString().padLeft(2, '0')}:00',
            'requested_exit_time': '${exitTime.hour.toString().padLeft(2, '0')}:${exitTime.minute.toString().padLeft(2, '0')}:00',
            'duration_hours': durationHours,
            'base_amount': baseAmount,
            'original_amount': baseAmount, // Set original amount same as base initially
            'platform_fee': 9.00, // Platform fee
            'discount_amount': 0.00,
            'discount_percent': 0.00,
            'extra_amount': 0.00,
            'extra_minutes': 0,
            'grace_period_minutes': 10,
            'payment_method': paymentMethod,
            'booking_status': 'pending',
            'payment_status': 'pending',
          })
          .select('''
            *,
            listings(
              parking_space_name,
              parking_address,
              latitude,
              longitude,
              hourly_rate_car,
              hourly_rate_bike
            )
          ''')
          .single();

      // Generate QR code data and update the booking
      final bookingId = response['id'] as String;
      final startDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        entryTime.hour,
        entryTime.minute,
      );
      final endDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        exitTime.hour,
        exitTime.minute,
      );

      final qrCode = QRService.generateBookingQR(
        bookingId: bookingId,
        parkingSpaceId: listingId,
        userId: userId,
        hostId: hostId,
        startTime: startDateTime,
        endTime: endDateTime,
        vehicleNumber: vehicleType,
        totalAmount: baseAmount,
      );

      final qrGeneratedAt = DateTime.now();
      final qrExpiry = endDateTime.add(const Duration(hours: 2)); // Valid 2 hours after booking ends

      // Update booking with QR code data
      await _supabase
          .from('bookings')
          .update({
            'qr_code': qrCode,
            'qr_generated_at': qrGeneratedAt.toIso8601String(),
            'qr_expiry': qrExpiry.toIso8601String(),
          })
          .eq('id', bookingId);

      debugPrint('✅ QR code generated and saved for booking: $bookingId');
      debugPrint('   - Generated at: $qrGeneratedAt');
      debugPrint('   - Expires at: $qrExpiry');

      debugPrint('✅ Booking created successfully! ID: ${response['id']}');
      return Booking.fromJson(response);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR creating booking: $e');
      debugPrint('📋 Error type: ${e.runtimeType}');
      debugPrint('📋 Stack trace: $stackTrace');

      final errorMessage = e.toString().toLowerCase();

      // Check for RLS policy error
      if (errorMessage.contains('row-level security') ||
          errorMessage.contains('policy') ||
          errorMessage.contains('new row violates')) {
        debugPrint('⚠️  RLS Policy Error: User is not authenticated or session expired');
        debugPrint('⚠️  User ID: $userId');
        debugPrint('⚠️  Suggestion: Check if user is logged in and RLS policies allow INSERT');
        throw Exception('Authentication error. Please log out and log in again.');
      }

      // Check for permission errors
      if (errorMessage.contains('permission denied') ||
          errorMessage.contains('insufficient privilege')) {
        debugPrint('⚠️  Permission Error: User lacks permission to insert bookings');
        throw Exception('You do not have permission to create bookings. Please contact support.');
      }

      // Log the full error for debugging
      debugPrint('⚠️  Full error details: $e');
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  /// Get all bookings for the current user
  Future<List<Booking>> getUserBookings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No authenticated user');
        return [];
      }

      debugPrint('📚 Fetching user bookings for: $userId');

      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            listings(
              parking_space_name,
              parking_address,
              latitude,
              longitude,
              hourly_rate_car,
              hourly_rate_bike
            )
          ''')
          .eq('renter_id', userId)
          .order('created_at', ascending: false);

      debugPrint('✅ Found ${response.length} bookings');
      debugPrint('📋 Raw response: $response');

      return (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching bookings: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to fetch bookings: ${e.toString()}');
    }
  }

  /// Get active bookings (confirmed or checked_in) for the current user
  Future<List<Booking>> getActiveBookings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No authenticated user');
        return [];
      }

      debugPrint('🔄 Fetching active bookings for: $userId');

      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            listings(
              parking_space_name,
              parking_address,
              latitude,
              longitude,
              hourly_rate_car,
              hourly_rate_bike
            )
          ''')
          .eq('renter_id', userId)
          .inFilter('booking_status', ['pending', 'confirmed', 'checked_in'])
          .order('booking_date', ascending: true);

      debugPrint('✅ Found ${response.length} active bookings');
      debugPrint('📋 Raw response: $response');

      return (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching active bookings: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to fetch active bookings: ${e.toString()}');
    }
  }

  /// Get completed/past bookings for the current user
  Future<List<Booking>> getPastBookings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      debugPrint('📜 Fetching past bookings for: $userId');

      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            listings(
              parking_space_name,
              parking_address,
              latitude,
              longitude,
              hourly_rate_car,
              hourly_rate_bike
            )
          ''')
          .eq('renter_id', userId)
          .inFilter('booking_status', ['completed', 'cancelled', 'expired'])
          .order('booking_date', ascending: false);

      debugPrint('✅ Found ${response.length} past bookings');
      debugPrint('📋 Raw response: $response');

      return (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching past bookings: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to fetch past bookings: ${e.toString()}');
    }
  }

  /// Get a specific booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      debugPrint('🔍 Fetching booking: $bookingId');

      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            listings!inner(
              parking_space_name,
              parking_address,
              latitude,
              longitude,
              hourly_rate_car,
              hourly_rate_bike
            )
          ''')
          .eq('id', bookingId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ Booking not found');
        return null;
      }

      debugPrint('✅ Booking found');
      return Booking.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching booking: $e');
      throw Exception('Failed to fetch booking: ${e.toString()}');
    }
  }

  /// Confirm a booking (update status from pending to confirmed)
  Future<Booking> confirmBooking(String bookingId, {
    String? transactionId,
    String? qrCode,
  }) async {
    try {
      debugPrint('✅ Confirming booking: $bookingId');

      final updateData = {
        'booking_status': 'confirmed',
        'payment_status': 'paid',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      if (qrCode != null) {
        updateData['qr_code'] = qrCode;
        updateData['qr_generated_at'] = DateTime.now().toIso8601String();
        // QR expires 24 hours after generation
        updateData['qr_expiry'] = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
      }

      final response = await _supabase
          .from('bookings')
          .update(updateData)
          .eq('id', bookingId)
          .select('''
            *,
            listings!inner(
              parking_space_name,
              parking_address,
              latitude,
              longitude,
              hourly_rate_car,
              hourly_rate_bike
            )
          ''')
          .single();

      debugPrint('✅ Booking confirmed successfully');
      return Booking.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error confirming booking: $e');
      throw Exception('Failed to confirm booking: ${e.toString()}');
    }
  }

  /// Cancel a booking
  Future<Booking> cancelBooking(String bookingId, {String? cancellationReason}) async {
    try {
      debugPrint('❌ Cancelling booking: $bookingId');

      final updateData = {
        'booking_status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (cancellationReason != null) {
        updateData['cancellation_reason'] = cancellationReason;
      }

      final response = await _supabase
          .from('bookings')
          .update(updateData)
          .eq('id', bookingId)
          .select('''
            *,
            listings!inner(
              parking_space_name,
              parking_address,
              latitude,
              longitude,
              hourly_rate_car,
              hourly_rate_bike
            )
          ''')
          .single();

      debugPrint('✅ Booking cancelled successfully');
      return Booking.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error cancelling booking: $e');
      throw Exception('Failed to cancel booking: ${e.toString()}');
    }
  }

  /// Get real-time stream of user bookings
  Stream<List<Booking>> watchUserBookings() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('renter_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Booking.fromJson(json)).toList());
  }

  /// Get real-time stream of active bookings
  Stream<List<Booking>> watchActiveBookings() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('renter_id', userId)
        .order('booking_date', ascending: true)
        .map((data) => data
            .map((json) => Booking.fromJson(json))
            .where((booking) => booking.isActive)
            .toList());
  }
}

/// Booking Model
class Booking {
  final String id; // Can be UUID string or text ID like 'BK-ABC123'
  final String listingId;
  final String renterId;
  final String hostId;
  final String vehicleType; // 'car' or 'bike'
  final DateTime bookingDate;
  final TimeOfDay? requestedEntryTime;
  final TimeOfDay? requestedExitTime;
  final int? durationHours;
  final double originalAmount; // Original price before discounts
  final double discountAmount; // Discount applied in rupees
  final double discountPercent; // Discount percentage
  final double baseAmount; // Final amount after discount (what user pays)
  final double platformFee; // Platform service fee (₹9.00)
  final String paymentStatus; // 'pending', 'paid', 'failed', 'refunded'
  final String? paymentMethod;
  final String? transactionId;
  final String? qrCode;
  final DateTime? qrGeneratedAt;
  final DateTime? qrExpiry;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkedInBy;
  final String? checkedOutBy;
  final int gracePeriodMinutes;
  final int extraMinutes;
  final double? extraRatePerMinute;
  final double extraAmount;
  final String? hostExtraDecision; // 'charge' or 'waive'
  final double? finalAmount;
  final String bookingStatus; // 'pending', 'confirmed', 'checked_in', 'completed', 'cancelled', 'expired'
  final String? cancellationReason;
  final String? expiryReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined listing data
  final String? parkingSpaceName;
  final String? parkingAddress;
  final double? latitude;
  final double? longitude;
  final double? hourlyRateCar;
  final double? hourlyRateBike;

  const Booking({
    required this.id,
    required this.listingId,
    required this.renterId,
    required this.hostId,
    required this.vehicleType,
    required this.bookingDate,
    this.requestedEntryTime,
    this.requestedExitTime,
    this.durationHours,
    this.originalAmount = 0,
    this.discountAmount = 0,
    this.discountPercent = 0,
    required this.baseAmount,
    this.platformFee = 9.0,
    required this.paymentStatus,
    this.paymentMethod,
    this.transactionId,
    this.qrCode,
    this.qrGeneratedAt,
    this.qrExpiry,
    this.checkInTime,
    this.checkOutTime,
    this.checkedInBy,
    this.checkedOutBy,
    this.gracePeriodMinutes = 10,
    this.extraMinutes = 0,
    this.extraRatePerMinute,
    this.extraAmount = 0,
    this.hostExtraDecision,
    this.finalAmount,
    required this.bookingStatus,
    this.cancellationReason,
    this.expiryReason,
    required this.createdAt,
    required this.updatedAt,
    this.parkingSpaceName,
    this.parkingAddress,
    this.latitude,
    this.longitude,
    this.hourlyRateCar,
    this.hourlyRateBike,
  });

  /// Convert from JSON (database response)
  factory Booking.fromJson(Map<String, dynamic> json) {
    // Extract listing data from nested object
    final listing = json['listings'] as Map<String, dynamic>?;

    // Parse time strings to TimeOfDay
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      return null;
    }

    return Booking(
      id: json['id'],
      listingId: json['listing_id'],
      renterId: json['renter_id'],
      hostId: json['host_id'],
      vehicleType: json['vehicle_type'],
      bookingDate: DateTime.parse(json['booking_date']),
      requestedEntryTime: parseTime(json['requested_entry_time']),
      requestedExitTime: parseTime(json['requested_exit_time']),
      durationHours: json['duration_hours'],
      originalAmount: json['original_amount'] != null
          ? (json['original_amount'] as num).toDouble()
          : 0,
      discountAmount: json['discount_amount'] != null
          ? (json['discount_amount'] as num).toDouble()
          : 0,
      discountPercent: json['discount_percent'] != null
          ? (json['discount_percent'] as num).toDouble()
          : 0,
      baseAmount: (json['base_amount'] as num).toDouble(),
      platformFee: json['platform_fee'] != null
          ? (json['platform_fee'] as num).toDouble()
          : 9.0,
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      transactionId: json['transaction_id'],
      qrCode: json['qr_code'],
      qrGeneratedAt: json['qr_generated_at'] != null
          ? DateTime.parse(json['qr_generated_at'])
          : null,
      qrExpiry: json['qr_expiry'] != null
          ? DateTime.parse(json['qr_expiry'])
          : null,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      checkedInBy: json['checked_in_by'],
      checkedOutBy: json['checked_out_by'],
      gracePeriodMinutes: json['grace_period_minutes'] ?? 10,
      extraMinutes: json['extra_minutes'] ?? 0,
      extraRatePerMinute: json['extra_rate_per_minute'] != null
          ? (json['extra_rate_per_minute'] as num).toDouble()
          : null,
      extraAmount: json['extra_amount'] != null
          ? (json['extra_amount'] as num).toDouble()
          : 0,
      hostExtraDecision: json['host_extra_decision'],
      finalAmount: json['final_amount'] != null
          ? (json['final_amount'] as num).toDouble()
          : null,
      bookingStatus: json['booking_status'],
      cancellationReason: json['cancellation_reason'],
      expiryReason: json['expiry_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      parkingSpaceName: listing?['parking_space_name'],
      parkingAddress: listing?['parking_address'],
      latitude: listing?['latitude'] != null
          ? (listing!['latitude'] as num).toDouble()
          : null,
      longitude: listing?['longitude'] != null
          ? (listing!['longitude'] as num).toDouble()
          : null,
      hourlyRateCar: listing?['hourly_rate_car'] != null
          ? (listing!['hourly_rate_car'] as num).toDouble()
          : null,
      hourlyRateBike: listing?['hourly_rate_bike'] != null
          ? (listing!['hourly_rate_bike'] as num).toDouble()
          : null,
    );
  }

  /// Get booking status color
  String get statusColor {
    switch (bookingStatus.toLowerCase()) {
      case 'completed':
        return '#10B981'; // Green
      case 'checked_in':
      case 'confirmed':
        return '#3B82F6'; // Blue
      case 'cancelled':
        return '#EF4444'; // Red
      case 'pending':
        return '#F59E0B'; // Yellow
      case 'expired':
        return '#6B7280'; // Gray
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Get duration text
  String get durationText {
    if (durationHours == null) return 'N/A';

    if (durationHours! >= 24) {
      final days = (durationHours! / 24).floor();
      final remainingHours = durationHours! % 24;
      return '$days day${days > 1 ? 's' : ''}${remainingHours > 0 ? ' $remainingHours hr' : ''}';
    }

    return '$durationHours hr';
  }

  /// Get formatted entry time
  String get formattedEntryTime {
    if (requestedEntryTime == null) return 'N/A';
    final hour = requestedEntryTime!.hour;
    final minute = requestedEntryTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Get formatted exit time
  String get formattedExitTime {
    if (requestedExitTime == null) return 'N/A';
    final hour = requestedExitTime!.hour;
    final minute = requestedExitTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Get formatted booking date
  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[bookingDate.month - 1]} ${bookingDate.day}, ${bookingDate.year}';
  }

  /// Check if booking is active
  bool get isActive => ['confirmed', 'checked_in'].contains(bookingStatus.toLowerCase());

  /// Check if booking is completed
  bool get isCompleted => bookingStatus.toLowerCase() == 'completed';

  /// Check if booking is cancelled
  bool get isCancelled => bookingStatus.toLowerCase() == 'cancelled';

  /// Check if booking is pending
  bool get isPending => bookingStatus.toLowerCase() == 'pending';

  /// Get display amount (final or base)
  double get displayAmount => finalAmount ?? baseAmount;

  /// Get total amount including platform fee
  double get totalWithPlatformFee => displayAmount + platformFee;

  /// Get savings amount
  double get savingsAmount => originalAmount > 0 ? originalAmount - baseAmount : 0;
}
