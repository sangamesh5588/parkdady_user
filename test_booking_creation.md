# Booking Creation Debug Guide

## Issue
Payment completes successfully but booking doesn't appear in database or My Bookings screen.

## Root Cause
Row Level Security (RLS) policy on `bookings` table requires:
- `auth.uid() = renter_id` for INSERT operations
- This means the logged-in user ID must match the renter_id being inserted

## Current Users
1. sam@gmail.com - ID: `53567d29-23e0-49fb-b854-cc0be80011fb`
2. sangukarsanga7@gmail.com - ID: `909ef455-fefd-453b-bcc9-bb540205e84b`

## To Fix

### Step 1: Check Which User You're Logged In As
Run this in your terminal while the app is running:
```bash
flutter logs | grep "currentUser"
```

### Step 2: Enable Debug Logging
Add this to `lib/services/booking_service.dart` in `createBooking()` method (line 50):
```dart
final userId = _supabase.auth.currentUser?.id;
debugPrint('🔐 Current User ID: $userId');
debugPrint('📝 Creating booking with renter_id: $userId');
```

### Step 3: Check for RLS Errors
Look for these errors in logs:
- "new row violates row-level security policy"
- "Failed to create booking"
- "User not authenticated"

### Step 4: Test Booking Creation

1. **Make sure you're logged in** (check Profile tab shows your email)

2. **Try to book the parking**:
   - Select "sangu" parking
   - Choose date & time
   - Click "Confirm & Pay"
   - Complete payment (use test card: 4111 1111 1111 1111)

3. **Check logs immediately after payment**:
   ```bash
   flutter logs | grep -E "(Creating booking|Error|Failed)"
   ```

### Step 5: Verify Booking Was Created
After payment success, run this SQL in Supabase:
```sql
SELECT
  id,
  renter_id,
  booking_status,
  payment_status,
  created_at
FROM bookings
ORDER BY created_at DESC
LIMIT 1;
```

## Expected Flow

1. User completes payment in Razorpay
2. `_handlePaymentSuccess()` is called in `payment_screen.dart`
3. Line 473: `bookingService.createBooking()` is called
4. BookingService creates booking with `renter_id = current user ID`
5. Line 487: `bookingService.confirmBooking()` adds QR code
6. User navigates to success screen
7. Booking appears in "My Bookings" → "Active" tab

## Common Issues

### Issue 1: User Not Authenticated
**Symptom**: Error "User not authenticated"
**Fix**: Make sure user is logged in (check Profile tab)

### Issue 2: RLS Policy Violation
**Symptom**: Error "new row violates row-level security policy"
**Fix**: The logged-in user ID must match the renter_id
- This happens automatically if user is logged in
- Check: `_supabase.auth.currentUser?.id` matches booking renter_id

### Issue 3: Payment Succeeds But Booking Fails
**Symptom**: Payment success message but no booking in database
**Fix**: Add try-catch error logging in `_handlePaymentSuccess()`

### Issue 4: Booking Created But Not Visible
**Symptom**: Booking exists in database but not in app
**Fix**:
- Hot restart the app
- Check the booking status is 'pending', 'confirmed', or 'checked_in'
- Verify booking renter_id matches logged-in user

## Quick Test

Run this to create a test booking as the logged-in user:

```dart
// Add this button temporarily to your home screen
ElevatedButton(
  onPressed: () async {
    try {
      final bookingService = BookingService();
      final booking = await bookingService.createBooking(
        listingId: 'b6490d83-8d5d-471e-9ad7-bf867bfc8006',
        hostId: '53567d29-23e0-49fb-b854-cc0be80011fb',
        vehicleType: 'car',
        bookingDate: DateTime.now(),
        entryTime: TimeOfDay(hour: 10, minute: 0),
        exitTime: TimeOfDay(hour: 14, minute: 0),
        durationHours: 4,
        baseAmount: 400,
        paymentMethod: 'test',
      );
      print('✅ Test booking created: ${booking.id}');
    } catch (e) {
      print('❌ Test booking failed: $e');
    }
  },
  child: Text('TEST CREATE BOOKING'),
)
```

## Next Steps

1. Check the flutter logs while creating a booking
2. Look for error messages
3. Verify the user is logged in
4. Check if booking appears in Supabase after payment

If you share the error logs, I can provide a more specific fix!
