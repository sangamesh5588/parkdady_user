-- ================================================================
-- PARKING APP - FINAL MIGRATION
-- ================================================================
-- This script creates helper functions to work with your existing
-- 'listings' and 'parking_active_slots' tables
-- ================================================================

-- ================================================================
-- 1. CREATE HELPER FUNCTION FOR NEARBY AVAILABLE LISTINGS
-- ================================================================

-- Function to get available parking listings near a location
-- This joins listings with parking_active_slots to show only available spots
CREATE OR REPLACE FUNCTION public.get_nearby_available_listings(
  user_lat DECIMAL,
  user_lon DECIMAL,
  radius_meters INTEGER DEFAULT 5000,
  result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  host_id UUID,
  parking_space_name TEXT,
  parking_address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  landmark TEXT,
  parking_type TEXT,
  is_24x7 BOOLEAN,
  amenities TEXT[],
  open_time TIME,
  close_time TIME,
  total_bike_slots INTEGER,
  total_car_slots INTEGER,
  pricing_model TEXT,
  entrance_photo_url TEXT,
  parking_photos TEXT[],
  hourly_rate_car NUMERIC,
  daily_rate_car NUMERIC,
  hourly_rate_bike NUMERIC,
  daily_rate_bike NUMERIC,
  active_car_slots INTEGER,
  active_bike_slots INTEGER,
  distance_meters DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id,
    l.host_id,
    l.parking_space_name,
    l.parking_address,
    l.latitude,
    l.longitude,
    l.landmark,
    l.parking_type,
    l.is_24x7,
    l.amenities,
    l.open_time,
    l.close_time,
    l.total_bike_slots,
    l.total_car_slots,
    l.pricing_model,
    l.entrance_photo_url,
    l.parking_photos,
    l.hourly_rate_car,
    l.daily_rate_car,
    l.hourly_rate_bike,
    l.daily_rate_bike,
    COALESCE(pas.active_car_slots, 0) as active_car_slots,
    COALESCE(pas.active_bike_slots, 0) as active_bike_slots,
    -- Calculate distance in meters using Haversine formula
    (
      6371000 * acos(
        cos(radians(user_lat)) *
        cos(radians(l.latitude)) *
        cos(radians(l.longitude) - radians(user_lon)) +
        sin(radians(user_lat)) *
        sin(radians(l.latitude))
      )
    ) AS distance_meters
  FROM public.listings l
  LEFT JOIN public.parking_active_slots pas ON pas.listing_id = l.id AND pas.date = CURRENT_DATE
  WHERE
    l.latitude IS NOT NULL
    AND l.longitude IS NOT NULL
    AND l.status = 'approved'
    -- Only show listings with available slots for TODAY
    AND (COALESCE(pas.active_car_slots, 0) > 0 OR COALESCE(pas.active_bike_slots, 0) > 0)
    -- Simple bounding box filter (much faster)
    AND l.latitude BETWEEN (user_lat - (radius_meters / 111000.0)) AND (user_lat + (radius_meters / 111000.0))
    AND l.longitude BETWEEN (user_lon - (radius_meters / (111000.0 * cos(radians(user_lat))))) AND (user_lon + (radius_meters / (111000.0 * cos(radians(user_lat)))))
    -- Filter by opening hours: show only if 24x7 OR currently within open/close time
    AND (
      l.is_24x7 = TRUE
      OR (
        l.open_time IS NOT NULL
        AND l.close_time IS NOT NULL
        AND CURRENT_TIME BETWEEN l.open_time AND l.close_time
      )
    )
  ORDER BY distance_meters ASC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ================================================================
-- 2. CREATE FUNCTION TO GET ALL AVAILABLE LISTINGS
-- ================================================================

CREATE OR REPLACE FUNCTION public.get_all_available_listings(
  result_limit INTEGER DEFAULT 50,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  host_id UUID,
  parking_space_name TEXT,
  parking_address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  landmark TEXT,
  parking_type TEXT,
  is_24x7 BOOLEAN,
  amenities TEXT[],
  open_time TIME,
  close_time TIME,
  total_bike_slots INTEGER,
  total_car_slots INTEGER,
  pricing_model TEXT,
  entrance_photo_url TEXT,
  parking_photos TEXT[],
  hourly_rate_car NUMERIC,
  daily_rate_car NUMERIC,
  hourly_rate_bike NUMERIC,
  daily_rate_bike NUMERIC,
  active_car_slots INTEGER,
  active_bike_slots INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id,
    l.host_id,
    l.parking_space_name,
    l.parking_address,
    l.latitude,
    l.longitude,
    l.landmark,
    l.parking_type,
    l.is_24x7,
    l.amenities,
    l.open_time,
    l.close_time,
    l.total_bike_slots,
    l.total_car_slots,
    l.pricing_model,
    l.entrance_photo_url,
    l.parking_photos,
    l.hourly_rate_car,
    l.daily_rate_car,
    l.hourly_rate_bike,
    l.daily_rate_bike,
    COALESCE(pas.active_car_slots, 0) as active_car_slots,
    COALESCE(pas.active_bike_slots, 0) as active_bike_slots
  FROM public.listings l
  LEFT JOIN public.parking_active_slots pas ON pas.listing_id = l.id AND pas.date = CURRENT_DATE
  WHERE
    l.status = 'approved'
    -- Only show listings with available slots for TODAY
    AND (COALESCE(pas.active_car_slots, 0) > 0 OR COALESCE(pas.active_bike_slots, 0) > 0)
    -- Filter by opening hours: show only if 24x7 OR currently within open/close time
    AND (
      l.is_24x7 = TRUE
      OR (
        l.open_time IS NOT NULL
        AND l.close_time IS NOT NULL
        AND CURRENT_TIME BETWEEN l.open_time AND l.close_time
      )
    )
  ORDER BY l.parking_space_name ASC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- ================================================================
-- 3. GRANT PERMISSIONS
-- ================================================================

-- Grant execute permissions on the functions
GRANT EXECUTE ON FUNCTION public.get_nearby_available_listings TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_all_available_listings TO anon, authenticated;

-- ================================================================
-- SETUP COMPLETE!
-- ================================================================
-- Created:
-- 1. get_nearby_available_listings() - Get nearby listings with availability
-- 2. get_all_available_listings() - Get all available listings
--
-- These functions automatically join listings with parking_active_slots
-- to show only listings that have available parking spots
-- ================================================================

SELECT 'Helper functions created successfully!' AS status;
