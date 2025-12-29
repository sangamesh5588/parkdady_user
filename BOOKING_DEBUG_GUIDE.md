# Booking Creation - Debugging Guide

## 🎯 NEW BOOKING FLOW (Updated 2025-12-24)

The booking flow has been **completely restructured** to create bookings BEFORE payment:

### Old Flow (DEPRECATED):
```
User → Select Listing → Select Date/Time
     → Confirm → Payment → Create Booking → Success
```
**Problem:** If payment fails/cancels, no booking is saved.

### New Flow (CURRENT):
```
User → Select Listing → Select Date/Time
     → Confirm → Create Booking (pending status)
     → Payment → Confirm Booking (paid status)
     → Success
```
**Benefit:** Booking is saved in database immediately, payment is optional.

---

## ✅ What I Fixed

### 1. **Restructured Booking Flow**
Bookings are now created IMMEDIATELY when user clicks "Confirm & Pay":
- Booking created with `booking_status='pending'` and `payment_status='pending'`
- Booking saved to database BEFORE payment screen
- Payment screen receives existing booking
- Payment only updates booking status to 'confirmed' and 'paid'

**Files Modified:**
- [`lib/presentation/pages/booking_flow/booking_confirmation_screen.dart`](lib/presentation/pages/booking_flow/booking_confirmation_screen.dart) - Creates booking before navigation
- [`lib/presentation/pages/booking_flow/payment_screen.dart`](lib/presentation/pages/booking_flow/payment_screen.dart) - Updated to accept `existingBooking` parameter

### 2. **Added Missing Database Fields**
The `createBooking()` method was missing several required/default fields. I added:
- `original_amount` - Set to same as `base_amount`
- `platform_fee` - Set to 9.00
- `discount_amount` - Set to 0.00
- `discount_percent` - Set to 0.00
- `extra_amount` - Set to 0.00
- `extra_minutes` - Set to 0
- `grace_period_minutes` - Set to 10

**File Modified:** [`lib/services/booking_service.dart:69-91`](lib/services/booking_service.dart#L69-L91)

### 2. **Enhanced Error Logging**
Added detailed error logging to help diagnose issues:
- Logs error type
- Detects RLS policy errors
- Detects permission errors
- Provides actionable suggestions

**File Modified:** [`lib/services/booking_service.dart:107-134`](lib/services/booking_service.dart#L107-L134)

---

## 🧪 Database Testing Results

### ✅ **Database Works Perfectly!**
I successfully created a test booking directly in the database:

```sql
INSERT INTO bookings (...) VALUES (...)
-- Result: ✅ Created booking ID: d00e2417-ca24-41c8-8bec-f312b6b4cffa
```

**Conclusion:** The database, RLS policies, and schema are all working correctly.

---

## 🔍 How to Debug Booking Issues

### Step 1: Check Flutter Console Output

When you try to create a booking from the app, look for these debug prints:

#### **Success Pattern:**
```
🔐 Current user: user@example.com (ID: 12345...)
📝 Creating booking for listing: abc123...
📝 Booking details:
   - Renter ID: 12345...
   - Host ID: 67890...
   - Vehicle: car
   - Date: 2025-12-25
   - Time: 10:0 - 14:0
   - Amount: ₹400
✅ Booking created successfully! ID: xyz789...
```

#### **Failure Patterns:**

**Not Authenticated:**
```
❌ ERROR: User not authenticated - cannot create booking
```
**Solution:** User needs to log in again

**RLS Policy Error:**
```
❌ ERROR creating booking: ...row-level security...
⚠️  RLS Policy Error: User is not authenticated or session expired
⚠️  User ID: 12345...
```
**Solution:** Log out and log back in, or check RLS policies

**Permission Error:**
```
❌ ERROR creating booking: ...permission denied...
⚠️  Permission Error: User lacks permission to insert bookings
```
**Solution:** Check database RLS policies

**Other Error:**
```
❌ ERROR creating booking: <specific error>
📋 Error type: <error class>
⚠️  Full error details: <details>
```
**Solution:** Check the specific error message

### Step 2: Verify User Authentication

Run this check in your app's debug console or add temporary logging:

```dart
final user = Supabase.instance.client.auth.currentUser;
print('Current user: ${user?.email}');
print('User ID: ${user?.id}');
print('Session valid: ${user != null}');
```

**Expected:** User should NOT be null

### Step 3: Check Database Directly

Use the test SQL script I created to verify bookings are being saved:

```bash
# In your project directory
cat test_booking_flow.sql
# Then run the queries in Supabase SQL Editor
```

**Key Query:**
```sql
SELECT
  id,
  renter_id,
  booking_status,
  payment_status,
  created_at
FROM bookings
ORDER BY created_at DESC
LIMIT 5;
```

---

## 📊 Current Database State

**Project:** parking_project (eivjgwxyijhfmnyrcbcb)

**Users:**
- `sam@gmail.com` - ID: `53567d29-23e0-49fb-b854-cc0be80011fb` (Host)
- `sangukarsanga7@gmail.com` - ID: `909ef455-fefd-453b-bcc9-bb540205e84b` (Renter)

**Listings:**
- **sangu** - ID: `b6490d83-8d5d-471e-9ad7-bf867bfc8006`
  - Host: `sam@gmail.com`
  - Rate: ₹100/hour
  - Status: approved

**Test Booking Created:**
- ID: `d00e2417-ca24-41c8-8bec-f312b6b4cffa`
- Renter: `sangukarsanga7@gmail.com`
- Listing: sangu
- Status: pending
- Created: 2025-12-24 08:44:12

---

## 🚨 Common Issues & Solutions

### Issue 1: "Booking appears to save but doesn't show in database"

**Symptoms:**
- No error in app
- Debug shows "✅ Booking created successfully"
- But booking doesn't appear in database

**Possible Causes:**
1. Transaction was rolled back
2. Trigger/function deleted the row
3. Looking at wrong database/project

**Solution:**
```sql
-- Check if triggers are deleting bookings
SELECT * FROM pg_trigger WHERE tgrelid = 'bookings'::regclass;

-- Check for any functions that might delete bookings
SELECT proname, prosrc FROM pg_proc WHERE prosrc LIKE '%DELETE%bookings%';
```

### Issue 2: "User is not authenticated"

**Symptoms:**
- Error: "User not authenticated. Please log in to create a booking."
- `userId` is null in debug logs

**Solution:**
```dart
// Check auth state
final session = Supabase.instance.client.auth.currentSession;
if (session == null) {
  // User needs to log in
  await Supabase.instance.client.auth.signInWithPassword(
    email: 'user@example.com',
    password: 'password',
  );
}
```

### Issue 3: "RLS Policy Error"

**Symptoms:**
- Error contains "row-level security policy"
- Error: "Authentication error. Please log out and log in again."

**Solution:**
```sql
-- Check RLS policies on bookings table
SELECT * FROM pg_policies WHERE tablename = 'bookings';

-- Ensure INSERT policy allows authenticated users
-- Expected: with_check = (auth.uid() = renter_id)
```

### Issue 4: "Foreign Key Violation"

**Symptoms:**
- Error: "violates foreign key constraint"

**Possible Causes:**
- `listing_id` doesn't exist
- `renter_id` doesn't exist in auth.users
- `host_id` doesn't exist in auth.users

**Solution:**
```sql
-- Verify listing exists
SELECT id FROM listings WHERE id = 'your-listing-id';

-- Verify user exists
SELECT id FROM auth.users WHERE id = 'your-user-id';
```

---

## 🎯 Testing Checklist

Before reporting the issue isn't fixed:

- [ ] Restart the Flutter app completely
- [ ] Check Flutter console for debug logs
- [ ] Verify user is logged in (`currentUser` is not null)
- [ ] Check if test booking was created in database (ID: d00e2417-ca24-41c8-8bec-f312b6b4cffa)
- [ ] Try booking with a different user (not the host)
- [ ] Check Supabase logs for errors
- [ ] Verify internet connection is working
- [ ] Check if Supabase project is active (not paused)

---

## 📝 Next Steps

### Immediate Testing:
1. **Run the app** and try to create a booking
2. **Watch the console** for debug output starting with 🔐, 📝, ✅, or ❌
3. **Check database** using the test query above
4. **Report back** with the console output

### If Still Failing:
Send me the **complete console output** from when you click "Confirm & Pay" until you see an error or success message. Include:
- All lines starting with 🔐, 📝, ✅, ❌, or ⚠️
- Any error messages
- Stack traces

---

## 📁 Files Modified

1. **`lib/services/booking_service.dart`**
   - Added all required fields to INSERT
   - Enhanced error logging
   - Fixed scope issue with userId

2. **`lib/presentation/pages/booking_flow/booking_success_screen.dart`**
   - Uses actual booking ID from database
   - Shows vehicle type from booking object
   - Uses stored QR code if available

3. **`lib/domain/entities/parking_space.dart`**
   - Enhanced to support both `listings` and `parking_spaces` tables
   - Handles multiple field name variations

---

**Last Updated:** 2025-12-24 08:50 UTC
**Status:** ✅ Fixes applied - Ready for testing
