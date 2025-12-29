-- Insert active slots for today for the listing we created
-- This makes the parking space available for booking

-- First, let's insert active slots for today
INSERT INTO public.parking_active_slots (
  listing_id,
  date,
  active_car_slots,
  active_bike_slots,
  total_car_slots,
  total_bike_slots
)
SELECT
  id as listing_id,
  CURRENT_DATE as date,
  COALESCE(total_car_slots, 0) as active_car_slots,
  COALESCE(total_bike_slots, 0) as active_bike_slots,
  COALESCE(total_car_slots, 0) as total_car_slots,
  COALESCE(total_bike_slots, 0) as total_bike_slots
FROM public.listings
WHERE id IN (
  SELECT id FROM public.listings LIMIT 1
)
ON CONFLICT (listing_id, date)
DO UPDATE SET
  active_car_slots = EXCLUDED.active_car_slots,
  active_bike_slots = EXCLUDED.active_bike_slots,
  total_car_slots = EXCLUDED.total_car_slots,
  total_bike_slots = EXCLUDED.total_bike_slots;

-- Verify the data
SELECT
  l.parking_space_name,
  pas.date,
  pas.active_car_slots,
  pas.active_bike_slots,
  pas.total_car_slots,
  pas.total_bike_slots
FROM public.listings l
JOIN public.parking_active_slots pas ON pas.listing_id = l.id
WHERE pas.date = CURRENT_DATE;
