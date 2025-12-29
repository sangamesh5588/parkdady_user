-- ================================================================
-- PARKING AVAILABLE SLOTS AND USER PARKING LISTING TABLES
-- ================================================================
-- This script creates tables for managing available parking slots
-- and user parking listings for the home page
-- ================================================================

-- ================================================================
-- 1. CREATE parking_available_slots TABLE
-- ================================================================
-- This table stores individual parking slots that are available for booking

CREATE TABLE IF NOT EXISTS public.parking_available_slots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- Reference to the main parking space
  parking_space_id UUID NOT NULL REFERENCES public.parking_spaces(id) ON DELETE CASCADE,

  -- Slot details
  slot_number TEXT NOT NULL,
  slot_type TEXT DEFAULT 'standard' CHECK (slot_type IN ('standard', 'compact', 'ev', 'disabled', 'motorcycle')),

  -- Availability
  is_available BOOLEAN DEFAULT TRUE,
  available_from TIMESTAMPTZ DEFAULT NOW(),
  available_until TIMESTAMPTZ,

  -- Pricing (can override parking space pricing if needed)
  price_per_hour DECIMAL(10, 2),

  -- Metadata
  features JSONB DEFAULT '[]'::JSONB, -- e.g., ["covered", "near_entrance", "wide_space"]
  floor_level TEXT, -- e.g., "Ground", "B1", "Level 2"

  -- Booking reference
  current_booking_id TEXT REFERENCES public.bookings(id) ON DELETE SET NULL,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT unique_slot_per_space UNIQUE(parking_space_id, slot_number),
  CONSTRAINT valid_availability_dates CHECK (available_until IS NULL OR available_until > available_from)
) TABLESPACE pg_default;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS parking_available_slots_space_id_idx ON public.parking_available_slots(parking_space_id);
CREATE INDEX IF NOT EXISTS parking_available_slots_is_available_idx ON public.parking_available_slots(is_available);
CREATE INDEX IF NOT EXISTS parking_available_slots_availability_range_idx ON public.parking_available_slots USING GIST (tstzrange(available_from, available_until));
CREATE INDEX IF NOT EXISTS parking_available_slots_slot_type_idx ON public.parking_available_slots(slot_type);

-- ================================================================
-- 2. CREATE user_parking_listing TABLE
-- ================================================================
-- This table stores parking listings created by users (hosts)

CREATE TABLE IF NOT EXISTS public.user_parking_listing (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- Owner/Host information
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

  -- Listing details
  title TEXT NOT NULL,
  description TEXT,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  zip_code TEXT,
  country TEXT DEFAULT 'India',

  -- Location coordinates
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),

  -- Pricing
  price_per_hour DECIMAL(10, 2) NOT NULL CHECK (price_per_hour > 0),
  price_per_day DECIMAL(10, 2),
  minimum_hours DECIMAL(4, 2) DEFAULT 1.0,

  -- Capacity
  total_slots INTEGER NOT NULL DEFAULT 1 CHECK (total_slots > 0),
  available_slots INTEGER NOT NULL DEFAULT 1 CHECK (available_slots >= 0 AND available_slots <= total_slots),

  -- Features and amenities
  amenities JSONB DEFAULT '[]'::JSONB, -- ["covered", "cctv", "ev_charging", "24x7", "security_guard"]
  images JSONB DEFAULT '[]'::JSONB, -- Array of image URLs

  -- Availability schedule
  available_days JSONB DEFAULT '["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]'::JSONB,
  available_from_time TIME DEFAULT '00:00:00',
  available_to_time TIME DEFAULT '23:59:59',
  is_24x7 BOOLEAN DEFAULT FALSE,

  -- Booking settings
  instant_booking BOOLEAN DEFAULT TRUE,
  requires_approval BOOLEAN DEFAULT FALSE,
  advance_booking_days INTEGER DEFAULT 30,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_published BOOLEAN DEFAULT FALSE,
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),

  -- Additional rules
  parking_rules TEXT,
  access_instructions TEXT,

  -- Statistics
  total_bookings INTEGER DEFAULT 0,
  average_rating DECIMAL(3, 2),
  total_reviews INTEGER DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ,

  -- Constraints
  CONSTRAINT valid_coordinates CHECK (
    (latitude IS NULL AND longitude IS NULL) OR
    (latitude >= -90 AND latitude <= 90 AND longitude >= -180 AND longitude <= 180)
  ),
  CONSTRAINT valid_price_per_day CHECK (price_per_day IS NULL OR price_per_day > 0)
) TABLESPACE pg_default;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS user_parking_listing_user_id_idx ON public.user_parking_listing(user_id);
CREATE INDEX IF NOT EXISTS user_parking_listing_is_active_idx ON public.user_parking_listing(is_active);
CREATE INDEX IF NOT EXISTS user_parking_listing_is_published_idx ON public.user_parking_listing(is_published);
CREATE INDEX IF NOT EXISTS user_parking_listing_location_idx ON public.user_parking_listing USING GIST (point(longitude, latitude));
CREATE INDEX IF NOT EXISTS user_parking_listing_city_state_idx ON public.user_parking_listing(city, state);
CREATE INDEX IF NOT EXISTS user_parking_listing_verification_idx ON public.user_parking_listing(verification_status);
CREATE INDEX IF NOT EXISTS user_parking_listing_price_idx ON public.user_parking_listing(price_per_hour);

-- ================================================================
-- 3. CREATE TRIGGERS
-- ================================================================

-- Trigger to update updated_at timestamp for parking_available_slots
CREATE TRIGGER update_parking_available_slots_updated_at
  BEFORE UPDATE ON public.parking_available_slots
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Trigger to update updated_at timestamp for user_parking_listing
CREATE TRIGGER update_user_parking_listing_updated_at
  BEFORE UPDATE ON public.user_parking_listing
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Function to set published_at when is_published becomes true
CREATE OR REPLACE FUNCTION public.set_published_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_published = TRUE AND (OLD.is_published = FALSE OR OLD.is_published IS NULL) THEN
    NEW.published_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to set published_at
CREATE TRIGGER set_user_parking_listing_published_at
  BEFORE UPDATE ON public.user_parking_listing
  FOR EACH ROW
  EXECUTE FUNCTION public.set_published_at();

-- ================================================================
-- 4. ENABLE ROW LEVEL SECURITY (RLS)
-- ================================================================

ALTER TABLE public.parking_available_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_parking_listing ENABLE ROW LEVEL SECURITY;

-- ================================================================
-- 5. CREATE RLS POLICIES
-- ================================================================

-- Policies for parking_available_slots

-- Everyone can view available slots for active parking spaces
CREATE POLICY "Everyone can view available slots"
  ON public.parking_available_slots
  FOR SELECT
  USING (
    is_available = TRUE AND
    EXISTS (
      SELECT 1 FROM public.parking_spaces ps
      WHERE ps.id = parking_space_id AND ps.is_active = TRUE
    )
  );

-- Hosts can view all slots for their parking spaces
CREATE POLICY "Hosts can view slots for own spaces"
  ON public.parking_available_slots
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.parking_spaces ps
      WHERE ps.id = parking_space_id AND ps.host_id = auth.uid()
    )
  );

-- Hosts can insert slots for their parking spaces
CREATE POLICY "Hosts can insert slots for own spaces"
  ON public.parking_available_slots
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.parking_spaces ps
      WHERE ps.id = parking_space_id AND ps.host_id = auth.uid()
    )
  );

-- Hosts can update slots for their parking spaces
CREATE POLICY "Hosts can update slots for own spaces"
  ON public.parking_available_slots
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.parking_spaces ps
      WHERE ps.id = parking_space_id AND ps.host_id = auth.uid()
    )
  );

-- Hosts can delete slots for their parking spaces
CREATE POLICY "Hosts can delete slots for own spaces"
  ON public.parking_available_slots
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.parking_spaces ps
      WHERE ps.id = parking_space_id AND ps.host_id = auth.uid()
    )
  );

-- Policies for user_parking_listing

-- Everyone can view published and active listings
CREATE POLICY "Everyone can view published listings"
  ON public.user_parking_listing
  FOR SELECT
  USING (is_active = TRUE AND is_published = TRUE);

-- Users can view their own listings
CREATE POLICY "Users can view own listings"
  ON public.user_parking_listing
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own listings
CREATE POLICY "Users can insert own listings"
  ON public.user_parking_listing
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own listings
CREATE POLICY "Users can update own listings"
  ON public.user_parking_listing
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own listings
CREATE POLICY "Users can delete own listings"
  ON public.user_parking_listing
  FOR DELETE
  USING (auth.uid() = user_id);

-- ================================================================
-- 6. GRANT PERMISSIONS
-- ================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.parking_available_slots TO authenticated;
GRANT SELECT ON public.parking_available_slots TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_parking_listing TO authenticated;
GRANT SELECT ON public.user_parking_listing TO anon;
GRANT ALL ON public.parking_available_slots TO service_role;
GRANT ALL ON public.user_parking_listing TO service_role;

-- ================================================================
-- 7. CREATE HELPER FUNCTIONS
-- ================================================================

-- Function to get available parking listings near a location
CREATE OR REPLACE FUNCTION public.get_nearby_parking_listings(
  user_lat DECIMAL,
  user_lon DECIMAL,
  radius_meters INTEGER DEFAULT 5000,
  result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  title TEXT,
  description TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  latitude DECIMAL,
  longitude DECIMAL,
  price_per_hour DECIMAL,
  available_slots INTEGER,
  amenities JSONB,
  images JSONB,
  average_rating DECIMAL,
  total_reviews INTEGER,
  distance_meters DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    upl.id,
    upl.user_id,
    upl.title,
    upl.description,
    upl.address,
    upl.city,
    upl.state,
    upl.latitude,
    upl.longitude,
    upl.price_per_hour,
    upl.available_slots,
    upl.amenities,
    upl.images,
    upl.average_rating,
    upl.total_reviews,
    -- Calculate distance in meters using Haversine formula approximation
    (
      6371000 * acos(
        cos(radians(user_lat)) *
        cos(radians(upl.latitude)) *
        cos(radians(upl.longitude) - radians(user_lon)) +
        sin(radians(user_lat)) *
        sin(radians(upl.latitude))
      )
    ) AS distance_meters
  FROM public.user_parking_listing upl
  WHERE
    upl.is_active = TRUE
    AND upl.is_published = TRUE
    AND upl.available_slots > 0
    AND upl.latitude IS NOT NULL
    AND upl.longitude IS NOT NULL
    -- Simple bounding box filter (much faster than calculating distance for all rows)
    AND upl.latitude BETWEEN (user_lat - (radius_meters / 111000.0)) AND (user_lat + (radius_meters / 111000.0))
    AND upl.longitude BETWEEN (user_lon - (radius_meters / (111000.0 * cos(radians(user_lat))))) AND (user_lon + (radius_meters / (111000.0 * cos(radians(user_lat)))))
  ORDER BY distance_meters ASC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ================================================================
-- SETUP COMPLETE!
-- ================================================================
-- Tables created:
-- 1. parking_available_slots - Individual parking slots
-- 2. user_parking_listing - User parking listings
--
-- Run this script in your Supabase SQL Editor
-- ================================================================

SELECT 'Parking slots and listings tables created successfully!' AS status;
