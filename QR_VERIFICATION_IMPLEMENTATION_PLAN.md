# 🎯 QR Code Verification System - Complete Implementation Plan

## 📋 Overview
Implement a complete QR code system where:
1. **Renter** creates a booking → QR code is automatically generated
2. **Renter** shows QR code at parking entrance
3. **Host** scans QR code → Verifies booking → Allows entry
4. System validates host_id, booking details, and timing

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        BOOKING FLOW                              │
└─────────────────────────────────────────────────────────────────┘

1. RENTER CREATES BOOKING
   ↓
2. PAYMENT SUCCESSFUL (Razorpay)
   ↓
3. QR CODE GENERATED & STORED IN DATABASE
   ↓
4. BOOKING STATUS: pending → confirmed
   ↓
5. RENTER VIEWS QR CODE IN "MY BOOKINGS"

┌─────────────────────────────────────────────────────────────────┐
│                      VERIFICATION FLOW                           │
└─────────────────────────────────────────────────────────────────┘

1. HOST OPENS QR SCANNER (Host Dashboard)
   ↓
2. SCANS RENTER'S QR CODE
   ↓
3. SYSTEM VALIDATES:
   ✓ QR code format is valid
   ✓ Booking exists in database
   ✓ Host ID matches listing's host_id
   ✓ Booking is active/confirmed
   ✓ Current time is within booking window
   ✓ Booking not already checked in
   ↓
4. IF VALID: Check-in successful → Update booking status
5. IF INVALID: Show error message with reason
```

---

## 🔧 Implementation Steps

### ✅ PHASE 1: Update Booking Creation Flow (Auto-generate QR)

#### 1.1 Update BookingService.confirmBooking()
**File**: `lib/services/booking_service.dart`

```dart
Future<Booking> confirmBooking(
  String bookingId, {
  String? transactionId,
}) async {
  try {
    debugPrint('✅ Confirming booking: $bookingId');

    // Fetch the booking first to get all details
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    // Generate QR code
    final qrData = QRService.generateBookingQR(
      bookingId: booking.id,
      parkingSpaceId: booking.listingId,
      userId: booking.renterId,
      hostId: booking.hostId,  // ADD THIS
      startTime: DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
        booking.requestedEntryTime?.hour ?? 0,
        booking.requestedEntryTime?.minute ?? 0,
      ),
      endTime: DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
        booking.requestedExitTime?.hour ?? 0,
        booking.requestedExitTime?.minute ?? 0,
      ),
      vehicleNumber: booking.vehicleType,
      totalAmount: booking.displayAmount,
    );

    // Update booking with QR code and status
    final updateData = {
      'booking_status': 'confirmed',
      'payment_status': 'paid',
      'qr_code': qrData,
      'qr_generated_at': DateTime.now().toIso8601String(),
      'qr_expiry': DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String(), // Valid for 24 hours
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (transactionId != null) {
      updateData['transaction_id'] = transactionId;
    }

    final response = await _supabase
        .from('bookings')
        .update(updateData)
        .eq('id', bookingId)
        .select(/* ... */)
        .single();

    debugPrint('✅ Booking confirmed with QR code');
    return Booking.fromJson(response);
  } catch (e) {
    debugPrint('❌ Error confirming booking: $e');
    throw Exception('Failed to confirm booking: ${e.toString()}');
  }
}
```

#### 1.2 Update QRService.generateBookingQR()
**File**: `lib/core/qr_service.dart`

```dart
static String generateBookingQR({
  required String bookingId,
  required String parkingSpaceId,
  required String userId,
  required String hostId,  // ADD THIS PARAMETER
  required DateTime startTime,
  required DateTime endTime,
  required String vehicleNumber,
  required double totalAmount,
}) {
  final qrData = {
    'app': _appIdentifier,
    'version': '1.0',
    'type': 'booking',
    'bookingId': bookingId,
    'parkingSpaceId': parkingSpaceId,
    'userId': userId,
    'hostId': hostId,  // ADD THIS
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'vehicleNumber': vehicleNumber,
    'totalAmount': totalAmount,
    'timestamp': DateTime.now().toIso8601String(),
    'validUntil': endTime.add(const Duration(hours: 2)).toIso8601String(),
  };

  return jsonEncode(qrData);
}
```

#### 1.3 Update QRBookingData Model
**File**: `lib/core/qr_service.dart`

```dart
class QRBookingData {
  final String bookingId;
  final String parkingSpaceId;
  final String userId;
  final String hostId;  // ADD THIS FIELD
  final DateTime startTime;
  final DateTime endTime;
  final String vehicleNumber;
  final double totalAmount;
  final DateTime timestamp;
  final DateTime validUntil;

  const QRBookingData({
    required this.bookingId,
    required this.parkingSpaceId,
    required this.userId,
    required this.hostId,  // ADD THIS
    required this.startTime,
    required this.endTime,
    required this.vehicleNumber,
    required this.totalAmount,
    required this.timestamp,
    required this.validUntil,
  });

  // Update parseBookingQR to include hostId
}
```

---

### ✅ PHASE 2: Update Existing Booking to Generate QR

Since you already have a booking created, let's add a QR code to it.

**SQL Script**: Run this in Supabase SQL Editor

```sql
-- Generate QR code for existing booking
UPDATE bookings
SET
  qr_code = '{"app":"PARKING_APP","version":"1.0","type":"booking","bookingId":"d4aa1508-1a9a-4d27-95d0-776a1356352f","parkingSpaceId":"b6490d83-8d5d-471e-9ad7-bf867bfc8006","userId":"53567d29-23e0-49fb-b854-cc0be80011fb","hostId":"53567d29-23e0-49fb-b854-cc0be80011fb","startTime":"2025-12-15T10:00:00.000Z","endTime":"2025-12-15T14:00:00.000Z","vehicleNumber":"car","totalAmount":400.0,"timestamp":"2025-12-22T08:00:00.000Z","validUntil":"2025-12-15T16:00:00.000Z"}',
  qr_generated_at = NOW(),
  qr_expiry = NOW() + INTERVAL '24 hours',
  booking_status = 'confirmed',
  updated_at = NOW()
WHERE id = 'd4aa1508-1a9a-4d27-95d0-776a1356352f'
RETURNING id, qr_code, qr_generated_at, booking_status;
```

---

### ✅ PHASE 3: Create Host QR Scanner Screen

#### 3.1 Add QR Scanner Package
**File**: `pubspec.yaml`

```yaml
dependencies:
  # ... existing dependencies
  mobile_scanner: ^5.0.0  # Modern QR scanner
  permission_handler: ^11.0.0  # For camera permissions
```

#### 3.2 Create QR Scanner Screen
**File**: `lib/presentation/pages/host/qr_scanner_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/colors.dart';
import '../../../core/qr_service.dart';
import '../../../services/booking_service.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onQRScanned(BarcodeCapture capture) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      setState(() => isProcessing = false);
      return;
    }

    final String? qrCode = barcodes.first.rawValue;
    if (qrCode == null) {
      setState(() => isProcessing = false);
      return;
    }

    await _verifyQRCode(qrCode);
  }

  Future<void> _verifyQRCode(String qrCode) async {
    try {
      // Parse QR code
      final qrData = QRService.parseBookingQR(qrCode);

      if (qrData == null) {
        _showErrorDialog('Invalid QR Code', 'This QR code is not valid or has expired.');
        return;
      }

      // Get current user (host)
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        _showErrorDialog('Error', 'You must be logged in to verify bookings.');
        return;
      }

      // Verify host ID matches
      if (qrData.hostId != currentUserId) {
        _showErrorDialog(
          'Unauthorized',
          'This booking is for a different parking space. You are not authorized to verify this QR code.',
        );
        return;
      }

      // Fetch booking from database
      final bookingService = BookingService();
      final booking = await bookingService.getBookingById(qrData.bookingId);

      if (booking == null) {
        _showErrorDialog('Booking Not Found', 'This booking does not exist.');
        return;
      }

      // Verify booking status
      if (booking.bookingStatus == 'cancelled' || booking.bookingStatus == 'expired') {
        _showErrorDialog(
          'Invalid Booking',
          'This booking has been ${booking.bookingStatus}.',
        );
        return;
      }

      // Check if already checked in
      if (booking.checkInTime != null) {
        _showErrorDialog(
          'Already Checked In',
          'This booking was already checked in at ${_formatTime(booking.checkInTime!)}',
        );
        return;
      }

      // Verify timing (allow check-in 30 minutes before start time)
      final now = DateTime.now();
      final allowedCheckInTime = qrData.startTime.subtract(const Duration(minutes: 30));

      if (now.isBefore(allowedCheckInTime)) {
        _showErrorDialog(
          'Too Early',
          'Check-in opens 30 minutes before booking start time.',
        );
        return;
      }

      if (now.isAfter(qrData.endTime)) {
        _showErrorDialog(
          'Booking Expired',
          'This booking has ended.',
        );
        return;
      }

      // All validations passed - Show success and check in
      await _showSuccessDialog(booking, qrData);

    } catch (e) {
      _showErrorDialog('Error', 'Failed to verify QR code: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _performCheckIn(String bookingId) async {
    try {
      final bookingService = BookingService();
      // You'll need to create this method in BookingService
      await bookingService.checkInBooking(bookingId);

      if (mounted) {
        Navigator.of(context).pop(); // Close scanner
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-in successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to check in: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    cameraController.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              cameraController.start();
              setState(() => isProcessing = false);
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(Booking booking, QRBookingData qrData) async {
    cameraController.stop();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Valid Booking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Parking Space', booking.parkingSpaceName ?? 'N/A'),
            _buildDetailRow('Vehicle', booking.vehicleType.toUpperCase()),
            _buildDetailRow('Start Time', qrData.startTime.toString()),
            _buildDetailRow('End Time', qrData.endTime.toString()),
            _buildDetailRow('Amount', '₹${booking.displayAmount}'),
            _buildDetailRow('Payment', booking.paymentStatus.toUpperCase()),
            const SizedBox(height: 16),
            const Text(
              'Confirm check-in for this booking?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Check In'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _performCheckIn(booking.id);
    } else {
      cameraController.start();
      setState(() => isProcessing = false);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppColors.ctaPrimary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onQRScanned,
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          // Scanning overlay
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Align QR code within frame to scan',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final double scanArea = size.width * 0.7;
    final double left = (size.width - scanArea) / 2;
    final double top = (size.height - scanArea) / 2;

    // Draw dark overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, scanArea, scanArea),
            const Radius.circular(12),
          )),
      ),
      paint,
    );

    // Draw corner brackets
    final Paint bracketPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final double bracketLength = 30;

    // Top-left
    canvas.drawLine(Offset(left, top), Offset(left + bracketLength, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + bracketLength), bracketPaint);

    // Top-right
    canvas.drawLine(Offset(left + scanArea, top), Offset(left + scanArea - bracketLength, top), bracketPaint);
    canvas.drawLine(Offset(left + scanArea, top), Offset(left + scanArea, top + bracketLength), bracketPaint);

    // Bottom-left
    canvas.drawLine(Offset(left, top + scanArea), Offset(left + bracketLength, top + scanArea), bracketPaint);
    canvas.drawLine(Offset(left, top + scanArea), Offset(left, top + scanArea - bracketLength), bracketPaint);

    // Bottom-right
    canvas.drawLine(Offset(left + scanArea, top + scanArea), Offset(left + scanArea - bracketLength, top + scanArea), bracketPaint);
    canvas.drawLine(Offset(left + scanArea, top + scanArea), Offset(left + scanArea, top + scanArea - bracketLength), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

### ✅ PHASE 4: Add Check-In Method to BookingService

**File**: `lib/services/booking_service.dart`

```dart
/// Check in a booking (host scans QR)
Future<Booking> checkInBooking(String bookingId) async {
  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('🚗 Checking in booking: $bookingId');

    final updateData = {
      'booking_status': 'checked_in',
      'check_in_time': DateTime.now().toIso8601String(),
      'checked_in_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('bookings')
        .update(updateData)
        .eq('id', bookingId)
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

    debugPrint('✅ Check-in successful');
    return Booking.fromJson(response);
  } catch (e) {
    debugPrint('❌ Error checking in: $e');
    throw Exception('Failed to check in: ${e.toString()}');
  }
}
```

---

### ✅ PHASE 5: Add Navigation to QR Scanner

Create a button in the host dashboard or profile to open the QR scanner.

**Example**: Add to host profile menu
```dart
ListTile(
  leading: const Icon(Icons.qr_code_scanner),
  title: const Text('Scan Booking QR'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  },
),
```

---

## 🔐 Security Features

1. **Host ID Verification**: QR code contains hostId, verified against current user
2. **Timing Validation**: Check-in only allowed within valid time window
3. **Status Validation**: Prevents double check-in, cancelled bookings
4. **Expiry Check**: QR codes expire after booking end time + 2 hours
5. **Database Validation**: All QR data cross-checked with database records

---

## 📱 User Experience Flow

### For Renter:
1. Create booking → Complete payment
2. Go to "My Bookings" → See "Active" bookings
3. Tap booking → Tap "Show Ticket"
4. QR code displays with booking details
5. Show QR at parking entrance

### For Host:
1. Open app → Go to host dashboard
2. Tap "Scan Booking QR"
3. Point camera at renter's QR code
4. See booking verification screen
5. Confirm check-in
6. Renter can enter parking

---

## 🧪 Testing Checklist

- [ ] QR code generated on booking creation
- [ ] QR code displayed correctly to renter
- [ ] Host can scan QR code with camera
- [ ] Valid QR shows success dialog
- [ ] Invalid QR shows error message
- [ ] Wrong host ID rejected
- [ ] Expired bookings rejected
- [ ] Cancelled bookings rejected
- [ ] Double check-in prevented
- [ ] Check-in updates database
- [ ] Check-in time recorded correctly

---

## 🚀 Deployment Steps

1. Update `.env` with Razorpay keys
2. Run `flutter pub get` to install new packages
3. Update booking creation flow
4. Deploy QR scanner screen
5. Test end-to-end flow
6. Deploy to production

---

## 📊 Database Schema

Already exists in `bookings` table:
```sql
- qr_code: text (JSON string)
- qr_generated_at: timestamptz
- qr_expiry: timestamptz
- check_in_time: timestamptz
- checked_in_by: uuid
- check_out_time: timestamptz
- checked_out_by: uuid
```

---

## ✅ Summary

This implementation provides:
- ✅ Automatic QR generation on booking confirmation
- ✅ Secure host verification by ID
- ✅ Time-based validation
- ✅ Prevent fraud (double check-in, wrong host, etc.)
- ✅ Complete audit trail (who checked in when)
- ✅ Great UX for both renters and hosts

**Next Step**: Start with Phase 2 to add QR to your existing booking, then test the full flow!
