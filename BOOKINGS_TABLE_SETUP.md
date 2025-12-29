# 📋 Bookings Table Setup Guide

## 🎯 Overview

This guide will help you recreate the bookings table in your Supabase database with the correct schema that matches your Flutter app.

**Problem:** Column name mismatch and missing fields causing bookings not to save
**Solution:** Drop and recreate bookings table with proper schema

---

## 📝 Step-by-Step Instructions

### Step 1: Access Supabase SQL Editor

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project: **parking_project** (eivjgwxyijhfmnyrcbcb)
3. Click on **SQL Editor** in the left sidebar
4. Click **New Query**

### Step 2: Execute the Recreation Script

1. Open the file: [recreate_bookings_table.sql](recreate_bookings_table.sql)
2. Copy the ENTIRE contents of the file
3. Paste it into the Supabase SQL Editor
4. Click **Run** button (or press Ctrl+Enter)

### Step 3: Verify the Setup

After running the script, you should see messages like:
```
✅ Bookings table recreated successfully!
✅ RLS policies enabled
✅ Indexes created
✅ Triggers configured
```

Then run these verification queries one by one:

#### Query 1: Check Table Structure
```sql
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bookings'
ORDER BY ordinal_position;
```

**Expected:** You should see all 38 columns including:
- id, listing_id, renter_id, host_id
- vehicle_type, booking_date, requested_entry_time, requested_exit_time
- base_amount, original_amount, platform_fee, discount_amount, etc.

#### Query 2: Check Indexes
```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'bookings';
```

**Expected:** 7 indexes on renter_id, host_id, listing_id, booking_date, etc.

#### Query 3: Check RLS Policies
```sql
SELECT policyname, cmd
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'bookings';
```

**Expected:** 5 policies for SELECT, INSERT, UPDATE permissions

---

## 📊 New Bookings Table Schema

### Key Columns

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key (auto-generated) |
| `listing_id` | UUID | References listings table |
| `renter_id` | UUID | User who made the booking |
| `host_id` | UUID | Owner of the parking space |
| `vehicle_type` | TEXT | 'car', 'bike', or 'bicycle' |
| `booking_date` | DATE | Date of parking |
| `requested_entry_time` | TIME | Requested check-in time |
| `requested_exit_time` | TIME | Requested check-out time |
| `duration_hours` | INTEGER | Duration in hours |
| `base_amount` | NUMERIC | Final price (after discounts) |
| `original_amount` | NUMERIC | Original price (before discounts) |
| `platform_fee` | NUMERIC | Platform service fee (default 9.00) |
| `discount_amount` | NUMERIC | Discount in rupees |
| `discount_percent` | NUMERIC | Discount percentage |
| `extra_amount` | NUMERIC | Overtime charges |
| `booking_status` | TEXT | 'pending', 'confirmed', 'checked_in', 'completed', 'cancelled', 'expired' |
| `payment_status` | TEXT | 'pending', 'paid', 'failed', 'refunded' |
| `qr_code` | TEXT | Generated QR code |
| `created_at` | TIMESTAMPTZ | When booking was created |
| `updated_at` | TIMESTAMPTZ | Last update time |

### Status Flow

**Booking Status:**
```
pending → confirmed → checked_in → completed
              ↓
          cancelled
```

**Payment Status:**
```
pending → paid
    ↓
  failed → refunded
```

---

## 🔒 Row Level Security (RLS) Policies

The table has the following RLS policies enabled:

1. **Renters can view their bookings** - Users can see bookings where they are the renter
2. **Hosts can view their bookings** - Users can see bookings for their listings
3. **Users can create bookings** - Authenticated users can create new bookings
4. **Renters can update own bookings** - Users can update their own bookings
5. **Hosts can update bookings** - Hosts can update bookings for their listings

---

## 🧪 Testing the New Table

### Test 1: Create a Test Booking (Optional)

If you want to test manually in Supabase SQL Editor:

```sql
-- Replace these UUIDs with actual values from your database
INSERT INTO public.bookings (
  listing_id,
  renter_id,
  host_id,
  vehicle_type,
  booking_date,
  requested_entry_time,
  requested_exit_time,
  duration_hours,
  base_amount,
  original_amount,
  platform_fee,
  payment_method,
  booking_status,
  payment_status
) VALUES (
  'b6490d83-8d5d-471e-9ad7-bf867bfc8006', -- Your listing ID
  '909ef455-fefd-453b-bcc9-bb540205e84b', -- Renter ID (sangukarsanga7@gmail.com)
  '53567d29-23e0-49fb-b854-cc0be80011fb', -- Host ID (sam@gmail.com)
  'car',
  CURRENT_DATE,
  '10:00:00',
  '14:00:00',
  4,
  400.00,
  400.00,
  9.00,
  'pending',
  'pending',
  'pending'
) RETURNING *;
```

### Test 2: Verify Booking Was Created

```sql
SELECT
  id,
  listing_id,
  renter_id,
  booking_status,
  payment_status,
  base_amount,
  created_at
FROM public.bookings
ORDER BY created_at DESC
LIMIT 1;
```

---

## 🚀 Next Steps After Table Recreation

### 1. Update Flutter App (ALREADY DONE ✅)

The booking service (`lib/services/booking_service.dart`) already uses the correct column names:
- `renter_id` ✅
- `host_id` ✅
- `listing_id` ✅
- All pricing columns (original_amount, platform_fee, etc.) ✅

### 2. Test Booking Flow in App

1. Run your Flutter app:
   ```bash
   flutter run
   ```

2. Try to create a booking:
   - Select a parking listing
   - Choose date and time
   - Click "Confirm & Pay"

3. Watch console for:
   ```
   📝 Creating booking BEFORE payment...
   ✅ Booking created! ID: <uuid>
   ```

4. Check Supabase immediately:
   ```sql
   SELECT * FROM public.bookings ORDER BY created_at DESC LIMIT 1;
   ```

### 3. Verify Bookings Display

Check that bookings show up in:
- **My Bookings** screen (for renters)
- **Host Dashboard** (for hosts)
- **Listing details** page

---

## 🐛 Troubleshooting

### Issue: "Table does not exist"
**Solution:** Make sure you ran the entire script in Step 2

### Issue: "Permission denied"
**Solution:** Make sure you're logged into Supabase as the project owner

### Issue: "RLS policy error when creating booking"
**Solution:**
- Log out and log back into the Flutter app
- Make sure the user is authenticated before creating booking
- Check that `auth.uid()` matches `renter_id`

### Issue: "Foreign key constraint violation"
**Solution:**
- Verify the `listing_id` exists in the listings table
- Verify the `renter_id` and `host_id` exist in auth.users

---

## 📈 Monitoring Bookings

### View All Bookings
```sql
SELECT
  b.id,
  b.booking_status,
  b.payment_status,
  b.booking_date,
  b.base_amount,
  l.parking_space_name,
  p.full_name as renter_name,
  b.created_at
FROM bookings b
LEFT JOIN listings l ON b.listing_id = l.id
LEFT JOIN profiles p ON b.renter_id = p.id
ORDER BY b.created_at DESC;
```

### View Pending Bookings
```sql
SELECT
  id,
  listing_id,
  booking_status,
  payment_status,
  base_amount,
  created_at
FROM bookings
WHERE booking_status = 'pending'
ORDER BY created_at DESC;
```

### View Today's Bookings
```sql
SELECT
  id,
  listing_id,
  booking_date,
  requested_entry_time,
  requested_exit_time,
  booking_status,
  base_amount
FROM bookings
WHERE booking_date = CURRENT_DATE
ORDER BY requested_entry_time;
```

---

## ✅ Checklist

After completing this setup, check off these items:

- [ ] Executed `recreate_bookings_table.sql` in Supabase SQL Editor
- [ ] Verified table structure (38 columns)
- [ ] Verified indexes (7 indexes)
- [ ] Verified RLS policies (5 policies)
- [ ] Tested booking creation from Flutter app
- [ ] Confirmed booking saved to database
- [ ] Verified booking displays in app

---

## 📝 Summary

**What Changed:**
- ✅ Bookings table recreated with correct schema
- ✅ All required columns added (38 total)
- ✅ Proper indexes for performance
- ✅ RLS policies for security
- ✅ Triggers for auto-updating timestamps
- ✅ Column names match Flutter app exactly

**Result:**
Bookings will now be saved to the database correctly when users create them in the app!

---

**Last Updated:** 2025-12-27
**Status:** ✅ Ready to Execute
