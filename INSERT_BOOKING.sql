-- ============================================
-- CREATE BOOKING FROM PARKING ACTIVE SLOT
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Check the parking active slot and listing data
SELECT
  pas.id as slot_id,
  pas.listing_id,
  pas.date as slot_date,
  pas.active_car_slots,
  pas.active_bike_slots,
  l.parking_space_name,
  l.parking_address,
  l.hourly_rate_car,
  l.hourly_rate_bike,
  l.host_id
FROM parking_active_slots pas
JOIN listings l ON pas.listing_id = l.id
LIMIT 1;

-- Step 2: Get your user ID (the renter_id)
-- This will show all users - pick the one that's logged into your app
SELECT id, email, created_at
FROM auth.users
ORDER BY created_at DESC;

-- Step 3: Insert the booking
-- IMPORTANT: Replace <YOUR_USER_ID> with your actual user ID from Step 2
-- If you want to use the host as the renter (for testing), use the host_id from Step 1

INSERT INTO bookings (
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
  discount_amount,
  discount_percent,
  extra_amount,
  extra_minutes,
  grace_period_minutes,
  payment_status,
  payment_method,
  booking_status,
  created_at,
  updated_at
)
SELECT
  'b6490d83-8d5d-471e-9ad7-bf867bfc8006'::uuid,  -- listing_id from parking slot
  '53567d29-23e0-49fb-b854-cc0be80011fb'::uuid,  -- renter_id (REPLACE WITH YOUR USER ID)
  '53567d29-23e0-49fb-b854-cc0be80011fb'::uuid,  -- host_id
  'car',                                           -- vehicle_type
  '2025-12-15'::date,                             -- booking_date (from parking slot)
  '10:00:00'::time,                               -- requested_entry_time
  '14:00:00'::time,                               -- requested_exit_time
  4,                                               -- duration_hours (4 hours)
  400.00,                                          -- base_amount (₹100/hr * 4hrs = ₹400)
  400.00,                                          -- original_amount
  9.00,                                            -- platform_fee
  0.00,                                            -- discount_amount
  0.00,                                            -- discount_percent
  0.00,                                            -- extra_amount
  0,                                               -- extra_minutes
  10,                                              -- grace_period_minutes
  'paid',                                          -- payment_status
  'UPI',                                           -- payment_method
  'pending',                                       -- booking_status (will show in Active tab)
  NOW(),                                           -- created_at
  NOW()                                            -- updated_at
RETURNING *;

-- Step 4: Verify the booking was created with listing data (this is how the app queries it)
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
ORDER BY b.created_at DESC
LIMIT 1;

-- Step 5: Check how many active bookings exist
SELECT COUNT(*) as active_bookings
FROM bookings
WHERE booking_status IN ('pending', 'confirmed', 'checked_in');
