# Parking Listings Setup Guide

This guide will help you set up the new parking listings feature that fetches data from `user_parking_listing` and `parking_available_slots` tables in Supabase.

## What Was Done

### 1. Database Schema
Created two new tables in Supabase:
- **`user_parking_listing`**: Stores parking listings created by hosts
- **`parking_available_slots`**: Stores individual parking slots for each parking space

### 2. Entity Models
Created Dart entity models:
- `ParkingListing` ([lib/domain/entities/parking_listing.dart](lib/domain/entities/parking_listing.dart))
- `ParkingSlot` ([lib/domain/entities/parking_slot.dart](lib/domain/entities/parking_slot.dart))

### 3. Service Layer
Created `ParkingListingService` ([lib/services/parking_listing_service.dart](lib/services/parking_listing_service.dart)) with methods:
- `getNearbyListings()` - Fetch listings near user location
- `getAllListings()` - Get all published listings
- `getListingById()` - Get specific listing
- `searchListings()` - Search with filters
- `getAvailableSlots()` - Get available parking slots

### 4. Provider Updates
Updated [lib/presentation/providers/parking_provider.dart](lib/presentation/providers/parking_provider.dart):
- Added `parkingListingServiceProvider`
- Updated `HomeParkingNotifier` to use the new service
- Added `ParkingSpaceCard.fromParkingListing()` factory method

## Setup Instructions

### Step 1: Run the Database Migration

1. Open your Supabase project dashboard
2. Go to the **SQL Editor**
3. Open the file [parking_slots_migration.sql](parking_slots_migration.sql)
4. Copy the entire SQL content
5. Paste it into the Supabase SQL Editor
6. Click **Run** to execute the migration

This will create:
- `user_parking_listing` table
- `parking_available_slots` table
- RLS policies for security
- Helper function `get_nearby_parking_listings()` for location-based queries
- Proper indexes for performance

### Step 2: Verify the Tables

Run this SQL query in Supabase to verify the tables were created:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('user_parking_listing', 'parking_available_slots');
```

You should see both tables listed.

### Step 3: Add Sample Data (Optional)

To test the functionality, add some sample parking listings:

```sql
-- Insert a sample parking listing
INSERT INTO public.user_parking_listing (
  user_id,
  title,
  description,
  address,
  city,
  state,
  latitude,
  longitude,
  price_per_hour,
  total_slots,
  available_slots,
  amenities,
  images,
  is_active,
  is_published
) VALUES (
  auth.uid(), -- Your user ID
  'Downtown Parking Space',
  'Secure covered parking in the heart of downtown with 24/7 security',
  '123 Main Street',
  'Mumbai',
  'Maharashtra',
  19.0760,
  72.8777,
  50.00,
  5,
  5,
  '["covered", "cctv", "security_guard", "ev_charging"]'::jsonb,
  '[]'::jsonb,
  true,
  true
);
```

### Step 4: Test the Home Page

1. Run your Flutter app
2. Navigate to the home screen
3. The app should now fetch parking listings from the `user_parking_listing` table
4. Listings will be displayed with:
   - Distance from your current location
   - Price per hour
   - Available slots
   - Amenities (Covered, CCTV, EV Charging, etc.)
   - Average ratings

## How It Works

### Data Flow

```
User Opens Home Screen
    ↓
Location Service Gets Current Location
    ↓
HomeParkingNotifier._loadParkingSpaces()
    ↓
ParkingListingService.getNearbyListings()
    ↓
Supabase RPC: get_nearby_parking_listings()
    ↓
Returns listings sorted by distance
    ↓
Convert to ParkingSpaceCard
    ↓
Apply filters (amenities, price, etc.)
    ↓
Display on Home Screen
```

### Key Features

1. **Location-Based Search**: Uses PostgreSQL's geospatial functions to find nearby parking
2. **Distance Calculation**: Calculates real distance using Haversine formula
3. **Filtering**: Supports filtering by amenities, price, and more
4. **Real-Time Updates**: Uses Riverpod for reactive state management
5. **Security**: RLS policies ensure users only see published, active listings

## Database Schema Details

### user_parking_listing Table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Reference to profiles table |
| title | TEXT | Listing title |
| description | TEXT | Detailed description |
| address | TEXT | Full address |
| city | TEXT | City name |
| state | TEXT | State name |
| latitude | DECIMAL | GPS latitude |
| longitude | DECIMAL | GPS longitude |
| price_per_hour | DECIMAL | Hourly rate |
| total_slots | INTEGER | Total parking slots |
| available_slots | INTEGER | Currently available slots |
| amenities | JSONB | Array of amenities |
| images | JSONB | Array of image URLs |
| is_active | BOOLEAN | Whether listing is active |
| is_published | BOOLEAN | Whether listing is published |

### parking_available_slots Table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| parking_space_id | UUID | Reference to parking_spaces |
| slot_number | TEXT | Slot identifier (e.g., "A1") |
| slot_type | TEXT | Type: standard, compact, ev, disabled |
| is_available | BOOLEAN | Availability status |
| price_per_hour | DECIMAL | Optional override price |
| features | JSONB | Slot-specific features |
| floor_level | TEXT | Floor location |

## API Reference

### ParkingListingService Methods

```dart
// Get nearby listings based on location
Future<List<ParkingListingWithDistance>> getNearbyListings({
  required LocationData userLocation,
  double radiusInMeters = 5000,
  int limit = 20,
});

// Search listings with filters
Future<List<ParkingListing>> searchListings({
  required String query,
  String? city,
  String? state,
  double? maxPrice,
  List<String>? amenities,
  int limit = 20,
});

// Get available slots for a parking space
Future<List<ParkingSlot>> getAvailableSlots(String parkingSpaceId);
```

## Troubleshooting

### No Listings Showing

1. **Check if tables exist**: Run the verification query in Step 2
2. **Check RLS policies**: Ensure you're logged in and policies allow reading
3. **Check data**: Ensure listings have `is_active=true` and `is_published=true`
4. **Check location**: Ensure location permissions are granted

### Distance Not Calculating

1. Ensure listings have valid `latitude` and `longitude` values
2. Ensure user location is being fetched correctly
3. Check the `get_nearby_parking_listings()` function exists in Supabase

### Error: "function get_nearby_parking_listings does not exist"

Run the migration SQL again - the function might not have been created.

## Next Steps

### For Hosts (Listing Owners)
- Create a screen to add new parking listings
- Allow hosts to manage their listings
- Upload parking space images

### For Renters (Users)
- Implement booking flow
- Add favorites/saved listings
- Show booking history

### Enhancements
- Add real-time availability updates using Supabase Realtime
- Implement rating and review system
- Add payment integration
- Support for recurring bookings

## Support

If you encounter any issues:
1. Check the console logs for error messages
2. Verify your Supabase configuration in `.env`
3. Ensure all migration steps were completed
4. Check RLS policies in Supabase dashboard

## Files Modified/Created

### Created:
- `parking_slots_migration.sql` - Database migration
- `lib/domain/entities/parking_listing.dart` - ParkingListing entity
- `lib/domain/entities/parking_slot.dart` - ParkingSlot entity
- `lib/services/parking_listing_service.dart` - Service layer

### Modified:
- `lib/presentation/providers/parking_provider.dart` - Added new service provider and updated notifier
