# Database Verification Guide

## Current Issue Summary

Your app has two different data models:
- `ParkingSpace` - for marketplace listings (name, address, price, etc.)
- `ParkingSpot` - for daily slot availability (date, car_slots, bike_slots)

The ExploreScreen needs `ParkingSpot` data from either:
- `parking_spots` table, OR
- `parking_active_slots` table

## Steps to Fix

### 1. Check which table exists in your Supabase database

Go to Supabase Dashboard → SQL Editor and run:
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('parking_spots', 'parking_active_slots', 'parking_spaces');
```

### 2. Check the structure of existing tables

```sql
-- If you have parking_spots
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'parking_spots';

-- If you have parking_active_slots
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'parking_active_slots';
```

### 3. Create the parking_active_slots table if it doesn't exist

```sql
CREATE TABLE IF NOT EXISTS public.parking_active_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL UNIQUE,
  active_car_slots INTEGER NOT NULL DEFAULT 0,
  active_bike_slots INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.parking_active_slots ENABLE ROW LEVEL SECURITY;

-- Create policy to allow read access to everyone
CREATE POLICY "Allow read access to parking_active_slots"
ON public.parking_active_slots
FOR SELECT
TO public
USING (true);

-- Create policy to allow authenticated users to modify
CREATE POLICY "Allow authenticated users to modify parking_active_slots"
ON public.parking_active_slots
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);
```

### 4. Add sample data for testing

```sql
INSERT INTO public.parking_active_slots (date, active_car_slots, active_bike_slots)
VALUES
  (CURRENT_DATE, 10, 5),
  (CURRENT_DATE + INTERVAL '1 day', 8, 4),
  (CURRENT_DATE + INTERVAL '2 days', 12, 6),
  (CURRENT_DATE + INTERVAL '3 days', 15, 8),
  (CURRENT_DATE + INTERVAL '4 days', 9, 7)
ON CONFLICT (date)
DO UPDATE SET
  active_car_slots = EXCLUDED.active_car_slots,
  active_bike_slots = EXCLUDED.active_bike_slots,
  updated_at = NOW();
```

### 5. Alternative: If you want to use parking_spots table instead

Update `lib/services/parking_service.dart`:
- Change all `parking_active_slots` to `parking_spots`

### 6. Verify data exists

```sql
SELECT * FROM public.parking_active_slots ORDER BY date;
```

## After fixing the database

1. Restart your Flutter app
2. Pull down to refresh on the Explore screen
3. Data should now load successfully

## Current Code Status

✅ ExploreScreen correctly uses `parkingProvider` (returns `ParkingSpot`)
✅ ParkingService queries `parking_active_slots` table
❌ Table `parking_active_slots` might not exist in database
❌ OR table exists but has no data

Choose one option:
- **Option A**: Create `parking_active_slots` table (recommended - matches your code)
- **Option B**: Rename existing table to `parking_active_slots`
- **Option C**: Update code to use existing table name
