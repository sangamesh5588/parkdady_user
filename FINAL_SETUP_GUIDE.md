# Parking App - Final Setup Guide

This guide shows how to set up your parking app to fetch data from your **existing** `listings` and `parking_active_slots` tables in Supabase.

## What We Did

### 1. Created Helper Functions in Supabase
We created SQL functions that join your `listings` table with `parking_active_slots` to show only listings that have available parking spots.

### 2. Updated Flutter Code
- Created `ListingsService` to fetch data from your tables
- Updated `ParkingSpaceCard` to display data from your schema
- Modified `HomeParkingNotifier` to use the new service

## Step-by-Step Setup

### Step 1: Run the SQL Migration

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Open the file: [parking_final_migration.sql](parking_final_migration.sql)
4. Copy all the SQL code
5. Paste it into the Supabase SQL Editor
6. Click **Run**

This creates two helper functions:
- `get_nearby_available_listings()` - Get listings near user location with availability
- `get_all_available_listings()` - Get all available listings

### Step 2: Verify the Functions

Run this query to verify the functions were created:

```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_nearby_available_listings', 'get_all_available_listings');
```

You should see both functions listed.

### Step 3: Test with Sample Data

If you don't have data yet, add a test listing:

```sql
-- Insert a test listing
INSERT INTO public.listings (
  host_id,
  parking_space_name,
  parking_address,
  latitude,
  longitude,
  landmark,
  is_24x7,
  amenities,
  hourly_rate_car,
  total_car_slots
) VALUES (
  (SELECT id FROM auth.users LIMIT 1), -- Your user ID
  'Test Parking Space',
  '123 Main Street, Mumbai',
  19.0760,
  72.8777,
  'Near Railway Station',
  true,
  ARRAY['covered', 'cctv', 'security']::TEXT[],
  50.00,
  10
);

-- Add active slots for the listing
INSERT INTO public.parking_active_slots (
  listing_id,
  active_car_slots,
  active_bike_slots
) VALUES (
  (SELECT id FROM public.listings ORDER BY created_at DESC LIMIT 1),
  8,  -- 8 cars available
  5   -- 5 bikes available
);
```

### Step 4: Run Your Flutter App

The home page will now:
1. Get your current location
2. Call `get_nearby_available_listings()` with your location
3. Display listings within 5km radius that have available slots
4. Show distance, price, amenities, and available spots

## How It Works

### Data Flow

```
User Opens Home Screen
    ↓
LocationService gets GPS coordinates
    ↓
ListingsService.getNearbyListings()
    ↓
Calls Supabase RPC: get_nearby_available_listings()
    ↓
SQL Function joins listings + parking_active_slots
    ↓
Filters by:
  - Distance (within radius)
  - Availability (active_car_slots > 0 OR active_bike_slots > 0)
    ↓
Returns sorted by distance
    ↓
Convert to ParkingSpaceCard
    ↓
Display on Home Screen
```

### Key Features

✅ **Location-based search** - Find parking near you
✅ **Real availability** - Only shows listings with active slots
✅ **Distance calculation** - Haversine formula for accurate distance
✅ **Rich data** - Amenities, pricing, images, 24x7 status
✅ **Filtering** - By amenities, price, distance
✅ **Sorting** - By nearest or cheapest

## Database Schema Reference

### listings Table
Your existing schema includes:
- `id`, `host_id` - Identification
- `parking_space_name`, `parking_address` - Location info
- `latitude`, `longitude` - GPS coordinates
- `landmark` - Nearby landmark
- `is_24x7` - 24/7 availability
- `amenities` - Array of features
- `hourly_rate_car`, `daily_rate_car` - Car pricing
- `hourly_rate_bike`, `daily_rate_bike` - Bike pricing
- `total_car_slots`, `total_bike_slots` - Total capacity
- `entrance_photo_url`, `exit_photo_url` - Photos

### parking_active_slots Table
Tracks real-time availability:
- `id`, `listing_id` - Links to listings
- `active_car_slots` - Available car spots
- `active_bike_slots` - Available bike spots
- `created_at`, `updated_at` - Timestamps

## Files Modified/Created

### Created:
- ✅ `parking_final_migration.sql` - SQL functions for Supabase
- ✅ `lib/services/listings_service.dart` - Service to fetch from your tables
- ✅ `FINAL_SETUP_GUIDE.md` - This guide

### Modified:
- ✅ `lib/presentation/providers/parking_provider.dart`
  - Added `listingsServiceProvider`
  - Updated `HomeParkingNotifier` to use `ListingsService`
  - Updated `ParkingSpaceCard.fromListing()` to use your schema

## Testing the Integration

### 1. Check Location Permissions
Make sure your app has location permissions enabled.

### 2. Add Test Data
Use the SQL from Step 3 to add test listings with active slots.

### 3. Run the App
```bash
flutter run
```

### 4. Expected Behavior
- Home screen loads
- Location is fetched
- Nearby listings appear (if any within 5km)
- Each card shows:
  - Parking space name
  - Address with distance (e.g., "2.3km")
  - Price per hour (₹50/hr)
  - Available spots (e.g., "8 spots")
  - Amenities (Covered, CCTV, EV, etc.)
  - Photos (entrance/exit)

## Troubleshooting

### No listings showing?

1. **Check if functions exist:**
```sql
SELECT * FROM pg_proc WHERE proname = 'get_nearby_available_listings';
```

2. **Check if you have data:**
```sql
SELECT l.*, pas.active_car_slots, pas.active_bike_slots
FROM listings l
LEFT JOIN parking_active_slots pas ON pas.listing_id = l.id
WHERE (pas.active_car_slots > 0 OR pas.active_bike_slots > 0);
```

3. **Check location:**
   - Ensure GPS permissions are granted
   - Check console logs for location coordinates

### Error: "function get_nearby_available_listings does not exist"

Run the migration SQL again from Step 1.

### Distance always shows 0km

Check that your listings have valid `latitude` and `longitude` values.

## Next Steps

### For Better User Experience:

1. **Add Reviews** - Create a reviews table and link it
2. **Real-time Updates** - Use Supabase Realtime to update availability
3. **Booking Flow** - Allow users to book parking spots
4. **Host Dashboard** - Let hosts manage their listings and slots

### Recommended Enhancements:

```sql
-- Add reviews table
CREATE TABLE reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  listing_id UUID REFERENCES listings(id),
  user_id UUID REFERENCES profiles(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Update average rating in listings
CREATE OR REPLACE FUNCTION update_listing_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE listings
  SET average_rating = (
    SELECT AVG(rating) FROM reviews WHERE listing_id = NEW.listing_id
  )
  WHERE id = NEW.listing_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_rating_on_review
AFTER INSERT OR UPDATE ON reviews
FOR EACH ROW EXECUTE FUNCTION update_listing_rating();
```

## Support

If you encounter any issues:
1. Check the Flutter console for error messages
2. Verify Supabase configuration in `.env`
3. Ensure all migration steps were completed
4. Check RLS policies in Supabase dashboard

## Summary

Your parking app now:
- ✅ Fetches from your existing `listings` table
- ✅ Shows only available spots (from `parking_active_slots`)
- ✅ Calculates real distance from user location
- ✅ Displays rich data (amenities, pricing, photos)
- ✅ Supports filtering and sorting
- ✅ Ready for production use!

Happy parking! 🚗🅿️
