-- ================================================================
-- TEST BOOKING FLOW - VERIFICATION QUERIES
-- Use these queries to test and verify the booking system
-- ================================================================

-- ================================================================
-- STEP 1: VERIFY SCHEMA IS CORRECT
-- ================================================================

-- Check if all required columns exist in bookings table
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bookings'
  AND column_name IN (
    'id', 'listing_id', 'renter_id', 'host_id', 'vehicle_type',
    'booking_date', 'requested_entry_time', 'requested_exit_time',
    'original_amount', 'discount_amount', 'discount_percent',
    'base_amount', 'platform_fee', 'qr_code', 'qr_generated_at',
    'qr_expiry', 'payment_status', 'booking_status', 'transaction_id'
  )
ORDER BY column_name;

-- ================================================================
-- STEP 2: CHECK LISTINGS DATA
-- ================================================================

-- View available listings
SELECT
  id,
  parking_space_name,
  parking_address,
  host_id,
  hourly_rate_car,
  hourly_rate_bike,
  total_car_slots,
  status,
  latitude,
  longitude
FROM listings
WHERE status = 'approved'
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL
LIMIT 10;

-- Check parking_active_slots for availability
SELECT
  pas.date,
  pas.listing_id,
  l.parking_space_name,
  pas.active_car_slots,
  pas.active_bike_slots,
  l.total_car_slots
FROM parking_active_slots pas
JOIN listings l ON pas.listing_id = l.id
WHERE pas.date >= CURRENT_DATE
  AND (pas.active_car_slots > 0 OR pas.active_bike_slots > 0)
ORDER BY pas.date, l.parking_space_name
LIMIT 10;

-- ================================================================
-- STEP 3: CHECK CURRENT USER
-- ================================================================

-- Get current authenticated user
SELECT
  id as user_id,
  email,
  created_at
FROM auth.users
WHERE id = auth.uid();

-- Check if user has a profile
SELECT
  id,
  full_name,
  phone,
  role,
  onboarding_completed
FROM profiles
WHERE id = auth.uid();

-- ================================================================
-- STEP 4: CREATE A TEST BOOKING
-- ================================================================

-- First, get a valid listing ID and host ID
DO $$
DECLARE
  v_listing_id UUID;
  v_host_id UUID;
  v_renter_id UUID;
BEGIN
  -- Get current user ID
  v_renter_id := auth.uid();

  IF v_renter_id IS NULL THEN
    RAISE EXCEPTION 'No authenticated user. Please log in first.';
  END IF;

  -- Get first available listing
  SELECT id, host_id INTO v_listing_id, v_host_id
  FROM listings
  WHERE status = 'approved'
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
  LIMIT 1;

  IF v_listing_id IS NULL THEN
    RAISE EXCEPTION 'No approved listings found.';
  END IF;

  -- Create test booking
  INSERT INTO bookings (
    listing_id,
    renter_id,
    host_id,
    vehicle_type,
    booking_date,
    requested_entry_time,
    requested_exit_time,
    duration_hours,
    original_amount,
    discount_amount,
    discount_percent,
    base_amount,
    platform_fee,
    payment_status,
    payment_method,
    booking_status,
    created_at,
    updated_at
  ) VALUES (
    v_listing_id,
    v_renter_id,
    v_host_id,
    'car',
    CURRENT_DATE + INTERVAL '1 day',
    '10:00:00',
    '14:00:00',
    4,
    400.00,  -- original amount
    0.00,    -- no discount
    0.00,    -- no discount percentage
    400.00,  -- base amount (same as original)
    9.00,    -- platform fee
    'paid',
    'test',
    'confirmed',
    NOW(),
    NOW()
  );

  RAISE NOTICE 'Test booking created successfully for listing: %', v_listing_id;
END $$;

-- ================================================================
-- STEP 5: VIEW YOUR BOOKINGS
-- ================================================================

-- View all your bookings with listing details
SELECT
  b.id as booking_id,
  b.booking_status,
  b.payment_status,
  b.vehicle_type,
  b.booking_date,
  b.requested_entry_time,
  b.requested_exit_time,
  b.duration_hours,
  b.base_amount,
  b.platform_fee,
  b.original_amount,
  b.discount_amount,
  b.qr_code IS NOT NULL as has_qr,
  l.parking_space_name,
  l.parking_address,
  l.hourly_rate_car,
  b.created_at
FROM bookings b
LEFT JOIN listings l ON b.listing_id = l.id
WHERE b.renter_id = auth.uid()
ORDER BY b.created_at DESC;

-- ================================================================
-- STEP 6: VIEW ACTIVE BOOKINGS (Like the app does)
-- ================================================================

-- This mimics the app's getActiveBookings() query
SELECT
  b.*,
  l.parking_space_name,
  l.parking_address,
  l.latitude,
  l.longitude,
  l.hourly_rate_car,
  l.hourly_rate_bike
FROM bookings b
LEFT JOIN listings l ON b.listing_id = l.id
WHERE b.renter_id = auth.uid()
  AND b.booking_status IN ('pending', 'confirmed', 'checked_in')
ORDER BY b.booking_date ASC;

-- ================================================================
-- STEP 7: TEST BOOKING CONFIRMATION (Simulate payment success)
-- ================================================================

-- Update a pending booking to confirmed with QR code
-- Replace <BOOKING_ID> with an actual booking ID from step 5
/*
UPDATE bookings
SET
  booking_status = 'confirmed',
  payment_status = 'paid',
  transaction_id = 'test_txn_' || gen_random_uuid()::text,
  qr_code = 'QR_' || id || '_' || extract(epoch from now())::text,
  qr_generated_at = NOW(),
  qr_expiry = NOW() + INTERVAL '24 hours',
  updated_at = NOW()
WHERE id = '<BOOKING_ID>'
  AND renter_id = auth.uid()
RETURNING *;
*/

-- ================================================================
-- STEP 8: CHECK RLS POLICIES
-- ================================================================

-- View all policies on bookings table
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'bookings';

-- ================================================================
-- STEP 9: VERIFY DATA INTEGRITY
-- ================================================================

-- Check for bookings with missing listing data
SELECT
  b.id,
  b.listing_id,
  b.booking_status,
  l.id IS NULL as listing_missing
FROM bookings b
LEFT JOIN listings l ON b.listing_id = l.id
WHERE b.renter_id = auth.uid()
  AND l.id IS NULL;

-- Check for bookings with invalid amounts
SELECT
  id,
  base_amount,
  original_amount,
  discount_amount,
  platform_fee,
  final_amount
FROM bookings
WHERE renter_id = auth.uid()
  AND (
    base_amount IS NULL OR base_amount <= 0
    OR platform_fee IS NULL
    OR (original_amount > 0 AND base_amount > original_amount)
  );

-- ================================================================
-- STEP 10: CLEANUP TEST DATA (Optional)
-- ================================================================

-- Delete test bookings created by this script
/*
DELETE FROM bookings
WHERE renter_id = auth.uid()
  AND payment_method = 'test'
  AND created_at > NOW() - INTERVAL '1 hour';
*/

-- ================================================================
-- STATISTICS & SUMMARY
-- ================================================================

-- Count bookings by status
SELECT
  booking_status,
  COUNT(*) as count,
  SUM(base_amount) as total_amount
FROM bookings
WHERE renter_id = auth.uid()
GROUP BY booking_status
ORDER BY count DESC;

-- Count bookings by payment status
SELECT
  payment_status,
  COUNT(*) as count
FROM bookings
WHERE renter_id = auth.uid()
GROUP BY payment_status
ORDER BY count DESC;

-- Average booking duration and amount
SELECT
  AVG(duration_hours) as avg_duration_hours,
  AVG(base_amount) as avg_amount,
  MIN(base_amount) as min_amount,
  MAX(base_amount) as max_amount,
  COUNT(*) as total_bookings
FROM bookings
WHERE renter_id = auth.uid();

-- ================================================================
-- TROUBLESHOOTING QUERIES
-- ================================================================

-- Check if user can read from listings
SELECT COUNT(*) as visible_listings
FROM listings
WHERE status = 'approved';

-- Check if user can read from bookings
SELECT COUNT(*) as visible_bookings
FROM bookings;

-- Check if user can read their own bookings
SELECT COUNT(*) as my_bookings
FROM bookings
WHERE renter_id = auth.uid();

-- Show any errors in recent bookings
SELECT
  id,
  booking_status,
  payment_status,
  created_at,
  CASE
    WHEN listing_id IS NULL THEN 'Missing listing_id'
    WHEN renter_id IS NULL THEN 'Missing renter_id'
    WHEN host_id IS NULL THEN 'Missing host_id'
    WHEN base_amount <= 0 THEN 'Invalid amount'
    ELSE 'OK'
  END as validation_status
FROM bookings
WHERE renter_id = auth.uid()
ORDER BY created_at DESC
LIMIT 10;
