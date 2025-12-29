-- Create a test booking for the 'sangu' parking listing
-- Run this in Supabase SQL Editor

-- First, let's see the listing details
SELECT
  id,
  parking_space_name,
  parking_address,
  hourly_rate_car,
  hourly_rate_bike,
  host_id
FROM listings
WHERE parking_space_name = 'sangu';

-- Now insert a booking (replace the values after running the above query)
-- Make sure to replace:
-- - <LISTING_ID> with the actual listing ID from above
-- - <HOST_ID> with the actual host_id from above
-- - <RENTER_ID> with your actual user ID (get it from auth.users table or your app)

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
  payment_status,
  payment_method,
  booking_status,
  created_at,
  updated_at
) VALUES (
  'b6490d83-8d5d-471e-9ad7-bf867bfc8006',  -- listing_id (the 'sangu' listing)
  (SELECT id FROM auth.users LIMIT 1),      -- renter_id (your user ID)
  (SELECT host_id FROM listings WHERE id = 'b6490d83-8d5d-471e-9ad7-bf867bfc8006'),  -- host_id
  'car',                                     -- vehicle_type
  CURRENT_DATE,                              -- booking_date (today)
  '10:00:00',                                -- requested_entry_time
  '14:00:00',                                -- requested_exit_time
  4,                                         -- duration_hours
  292.00,                                    -- base_amount (73 * 4 hours)
  292.00,                                    -- original_amount
  9.00,                                      -- platform_fee
  'paid',                                    -- payment_status
  'UPI',                                     -- payment_method
  'pending',                                 -- booking_status
  NOW(),                                     -- created_at
  NOW()                                      -- updated_at
) RETURNING *;

-- Verify the booking was created with listing data
SELECT
  b.*,
  l.parking_space_name,
  l.parking_address,
  l.hourly_rate_car,
  l.hourly_rate_bike
FROM bookings b
LEFT JOIN listings l ON b.listing_id = l.id
ORDER BY b.created_at DESC
LIMIT 1;
