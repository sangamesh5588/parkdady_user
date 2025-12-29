-- Check if listings have latitude and longitude
SELECT
  id,
  parking_space_name,
  parking_address,
  latitude,
  longitude,
  CASE
    WHEN latitude IS NULL OR longitude IS NULL THEN 'MISSING COORDINATES'
    ELSE 'HAS COORDINATES'
  END as status
FROM listings
LIMIT 20;

-- If your listings don't have coordinates, here are some sample updates
-- for locations in Bangalore, Karnataka (adjust as needed for your actual addresses)

-- Example: Update a listing with coordinates for a location in Bangalore
-- UPDATE listings
-- SET
--   latitude = 12.9716,  -- Bangalore latitude
--   longitude = 77.5946  -- Bangalore longitude
-- WHERE id = 'your-listing-id-here';

-- Sample coordinates for various locations in Bangalore:
-- Koramangala: 12.9352, 77.6245
-- Indiranagar: 12.9716, 77.6412
-- Whitefield: 12.9698, 77.7499
-- Jayanagar: 12.9250, 77.5838
-- HSR Layout: 12.9121, 77.6446
-- Electronic City: 12.8456, 77.6603
-- MG Road: 12.9759, 77.6064
-- Malleshwaram: 13.0033, 77.5706

-- To update ALL listings with a default Bangalore location (only if they don't have coordinates):
-- UPDATE listings
-- SET
--   latitude = 12.9716 + (RANDOM() * 0.1 - 0.05),  -- Random coords within ~5km of Bangalore center
--   longitude = 77.5946 + (RANDOM() * 0.1 - 0.05)
-- WHERE latitude IS NULL OR longitude IS NULL;
