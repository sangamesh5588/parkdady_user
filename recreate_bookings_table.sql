-- ================================================================
-- RECREATE BOOKINGS TABLE - COMPLETE SETUP
-- ================================================================
-- This script drops and recreates the bookings table with correct schema
-- Run this in your Supabase SQL Editor
-- Project: eivjgwxyijhfmnyrcbcb (parking_project)
-- ================================================================

-- ================================================================
-- 1. DROP EXISTING BOOKINGS TABLE
-- ================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can insert own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can view bookings as host" ON public.bookings;
DROP POLICY IF EXISTS "Hosts can view their bookings" ON public.bookings;
DROP POLICY IF EXISTS "Renters can view their bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can create bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Hosts can update bookings" ON public.bookings;

-- Drop existing triggers
DROP TRIGGER IF EXISTS update_bookings_updated_at ON public.bookings;

-- Drop existing table
DROP TABLE IF EXISTS public.bookings CASCADE;

-- ================================================================
-- 2. CREATE BOOKINGS TABLE WITH CORRECT SCHEMA
-- ================================================================

CREATE TABLE public.bookings (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign Keys
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  renter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  host_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Booking Details
  vehicle_type TEXT NOT NULL CHECK (vehicle_type IN ('car', 'bike', 'bicycle')),
  booking_date DATE NOT NULL,
  requested_entry_time TIME NOT NULL,
  requested_exit_time TIME NOT NULL,
  actual_entry_time TIMESTAMPTZ,
  actual_exit_time TIMESTAMPTZ,
  duration_hours INTEGER NOT NULL CHECK (duration_hours > 0),

  -- Pricing
  base_amount NUMERIC(10,2) NOT NULL CHECK (base_amount >= 0),
  original_amount NUMERIC(10,2) DEFAULT 0 CHECK (original_amount >= 0),
  platform_fee NUMERIC(10,2) DEFAULT 9.00 CHECK (platform_fee >= 0),
  discount_amount NUMERIC(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
  discount_percent NUMERIC(5,2) DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
  extra_amount NUMERIC(10,2) DEFAULT 0 CHECK (extra_amount >= 0),
  final_amount NUMERIC(10,2),

  -- Time Tracking
  grace_period_minutes INTEGER DEFAULT 10 CHECK (grace_period_minutes >= 0),
  extra_minutes INTEGER DEFAULT 0 CHECK (extra_minutes >= 0),
  extra_rate_per_minute NUMERIC(10,2),

  -- Status
  booking_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (booking_status IN ('pending', 'confirmed', 'checked_in', 'completed', 'cancelled', 'expired')),
  payment_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  payment_method TEXT,
  transaction_id TEXT,

  -- QR Code
  qr_code TEXT,
  qr_generated_at TIMESTAMPTZ,
  qr_expiry TIMESTAMPTZ,

  -- Check-in/Check-out
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  checked_in_by TEXT,
  checked_out_by TEXT,

  -- Additional Info
  host_extra_decision TEXT,
  cancellation_reason TEXT,
  expiry_reason TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add table comment
COMMENT ON TABLE public.bookings IS 'Parking space bookings with complete lifecycle tracking';

-- Add column comments
COMMENT ON COLUMN public.bookings.renter_id IS 'User who made the booking';
COMMENT ON COLUMN public.bookings.host_id IS 'Owner of the parking space';
COMMENT ON COLUMN public.bookings.original_amount IS 'Original price before discounts';
COMMENT ON COLUMN public.bookings.base_amount IS 'Final price after discounts';
COMMENT ON COLUMN public.bookings.platform_fee IS 'Platform service fee';
COMMENT ON COLUMN public.bookings.extra_amount IS 'Additional charges for overtime';
COMMENT ON COLUMN public.bookings.grace_period_minutes IS 'Grace period before overtime charges';

-- ================================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- ================================================================

CREATE INDEX idx_bookings_renter_id ON public.bookings(renter_id);
CREATE INDEX idx_bookings_host_id ON public.bookings(host_id);
CREATE INDEX idx_bookings_listing_id ON public.bookings(listing_id);
CREATE INDEX idx_bookings_booking_date ON public.bookings(booking_date);
CREATE INDEX idx_bookings_booking_status ON public.bookings(booking_status);
CREATE INDEX idx_bookings_payment_status ON public.bookings(payment_status);
CREATE INDEX idx_bookings_created_at ON public.bookings(created_at);

-- ================================================================
-- 4. CREATE TRIGGER FOR UPDATED_AT
-- ================================================================

CREATE OR REPLACE FUNCTION public.update_bookings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_bookings_updated_at();

-- ================================================================
-- 5. ENABLE ROW LEVEL SECURITY (RLS)
-- ================================================================

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Policy: Renters can view their own bookings
CREATE POLICY "Renters can view their bookings"
  ON public.bookings
  FOR SELECT
  USING (auth.uid() = renter_id);

-- Policy: Hosts can view bookings for their listings
CREATE POLICY "Hosts can view their bookings"
  ON public.bookings
  FOR SELECT
  USING (auth.uid() = host_id);

-- Policy: Authenticated users can create bookings
CREATE POLICY "Users can create bookings"
  ON public.bookings
  FOR INSERT
  WITH CHECK (auth.uid() = renter_id);

-- Policy: Renters can update their own bookings
CREATE POLICY "Renters can update own bookings"
  ON public.bookings
  FOR UPDATE
  USING (auth.uid() = renter_id)
  WITH CHECK (auth.uid() = renter_id);

-- Policy: Hosts can update bookings for their listings
CREATE POLICY "Hosts can update bookings"
  ON public.bookings
  FOR UPDATE
  USING (auth.uid() = host_id)
  WITH CHECK (auth.uid() = host_id);

-- ================================================================
-- 6. GRANT PERMISSIONS
-- ================================================================

-- Grant schema access
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant table access
GRANT SELECT, INSERT, UPDATE ON public.bookings TO authenticated;

-- Service role has full access
GRANT ALL ON public.bookings TO service_role;

-- ================================================================
-- 7. VERIFICATION QUERIES
-- ================================================================

-- Check table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bookings'
ORDER BY ordinal_position;

-- Verify indexes
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'bookings';

-- Verify RLS policies
SELECT
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'bookings';

-- ================================================================
-- 8. TEST DATA (OPTIONAL - UNCOMMENT TO INSERT)
-- ================================================================

/*
-- Example: Create a test booking
-- Replace UUIDs with actual IDs from your database

INSERT INTO public.bookings (
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
  payment_method,
  booking_status,
  payment_status
) VALUES (
  'b6490d83-8d5d-471e-9ad7-bf867bfc8006', -- listing_id (sangu)
  '909ef455-fefd-453b-bcc9-bb540205e84b', -- renter_id (sangukarsanga7@gmail.com)
  '53567d29-23e0-49fb-b854-cc0be80011fb', -- host_id (sam@gmail.com)
  'car',
  CURRENT_DATE,
  '10:00:00',
  '14:00:00',
  4,
  400.00,
  400.00,
  9.00,
  'pending',
  'pending',
  'pending'
) RETURNING *;
*/

-- ================================================================
-- SETUP COMPLETE!
-- ================================================================
-- Run the verification queries above to confirm the table is created correctly
-- The bookings table is now ready to use with your Flutter app
-- ================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Bookings table recreated successfully!';
  RAISE NOTICE '✅ RLS policies enabled';
  RAISE NOTICE '✅ Indexes created';
  RAISE NOTICE '✅ Triggers configured';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Next steps:';
  RAISE NOTICE '1. Run the verification queries above';
  RAISE NOTICE '2. Test booking creation from your Flutter app';
  RAISE NOTICE '3. Check that bookings are saved to the database';
END $$;
