-- Supabase RPC Function to get nearby available parking listings
-- This function joins listings with parking_active_slots and calculates distance

CREATE OR REPLACE FUNCTION get_nearby_available_listings(
  user_lat DOUBLE PRECISION,
  user_lon DOUBLE PRECISION,
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
  open_time TEXT,
  close_time TEXT,
  total_bike_slots INTEGER,
  total_car_slots INTEGER,
  pricing_model TEXT,
  entrance_photo_url TEXT,
  parking_photos TEXT[],
  hourly_rate_car DOUBLE PRECISION,
  daily_rate_car DOUBLE PRECISION,
  hourly_rate_bike DOUBLE PRECISION,
  daily_rate_bike DOUBLE PRECISION,
  hourly_discount_car DOUBLE PRECISION,
  hourly_discount_bike DOUBLE PRECISION,
  daily_discount_car DOUBLE PRECISION,
  daily_discount_bike DOUBLE PRECISION,
  hourly_discount_car_percent DOUBLE PRECISION,
  hourly_discount_bike_percent DOUBLE PRECISION,
  daily_discount_car_percent DOUBLE PRECISION,
  daily_discount_bike_percent DOUBLE PRECISION,
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
    l.hourly_discount_car,
    l.hourly_discount_bike,
    l.daily_discount_car,
    l.daily_discount_bike,
    l.hourly_discount_car_percent,
    l.hourly_discount_bike_percent,
    l.daily_discount_car_percent,
    l.daily_discount_bike_percent,
    pas.active_car_slots,
    pas.active_bike_slots,
    -- Calculate distance using Haversine formula (in meters)
    (
      6371000 * acos(
        cos(radians(user_lat)) *
        cos(radians(l.latitude)) *
        cos(radians(l.longitude) - radians(user_lon)) +
        sin(radians(user_lat)) *
        sin(radians(l.latitude))
      )
    ) AS distance_meters
  FROM
    listings l
  LEFT JOIN
    parking_active_slots pas ON l.id = pas.listing_id AND pas.date = CURRENT_DATE
  WHERE
    l.latitude IS NOT NULL
    AND l.longitude IS NOT NULL
    AND (pas.active_car_slots > 0 OR pas.active_bike_slots > 0)
    -- Distance filter using bounding box for performance
    AND l.latitude BETWEEN (user_lat - (radius_meters / 111320.0))
                       AND (user_lat + (radius_meters / 111320.0))
    AND l.longitude BETWEEN (user_lon - (radius_meters / (111320.0 * cos(radians(user_lat)))))
                        AND (user_lon + (radius_meters / (111320.0 * cos(radians(user_lat)))))
  HAVING
    -- Final distance check using Haversine
    (
      6371000 * acos(
        cos(radians(user_lat)) *
        cos(radians(l.latitude)) *
        cos(radians(l.longitude) - radians(user_lon)) +
        sin(radians(user_lat)) *
        sin(radians(l.latitude))
      )
    ) <= radius_meters
  ORDER BY
    distance_meters ASC
  LIMIT
    result_limit;
END;
$$ LANGUAGE plpgsql;


-- Alternative: Get all available listings (without location filtering)
CREATE OR REPLACE FUNCTION get_all_available_listings(
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
  open_time TEXT,
  close_time TEXT,
  total_bike_slots INTEGER,
  total_car_slots INTEGER,
  pricing_model TEXT,
  entrance_photo_url TEXT,
  parking_photos TEXT[],
  hourly_rate_car DOUBLE PRECISION,
  daily_rate_car DOUBLE PRECISION,
  hourly_rate_bike DOUBLE PRECISION,
  daily_rate_bike DOUBLE PRECISION,
  hourly_discount_car DOUBLE PRECISION,
  hourly_discount_bike DOUBLE PRECISION,
  daily_discount_car DOUBLE PRECISION,
  daily_discount_bike DOUBLE PRECISION,
  hourly_discount_car_percent DOUBLE PRECISION,
  hourly_discount_bike_percent DOUBLE PRECISION,
  daily_discount_car_percent DOUBLE PRECISION,
  daily_discount_bike_percent DOUBLE PRECISION,
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
    l.hourly_discount_car,
    l.hourly_discount_bike,
    l.daily_discount_car,
    l.daily_discount_bike,
    l.hourly_discount_car_percent,
    l.hourly_discount_bike_percent,
    l.daily_discount_car_percent,
    l.daily_discount_bike_percent,
    pas.active_car_slots,
    pas.active_bike_slots
  FROM
    listings l
  LEFT JOIN
    parking_active_slots pas ON l.id = pas.listing_id AND pas.date = CURRENT_DATE
  WHERE
    (pas.active_car_slots > 0 OR pas.active_bike_slots > 0)
  ORDER BY
    l.parking_space_name ASC
  LIMIT
    result_limit
  OFFSET
    result_offset;
END;
$$ LANGUAGE plpgsql;
