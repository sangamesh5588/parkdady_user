-- ================================================================
-- FIX BOOKINGS TABLE SCHEMA
-- Run this in Supabase SQL Editor to align with the Flutter app
-- ================================================================

-- Check if bookings table exists and view its structure
DO $$
BEGIN
  -- Check if the table exists
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'bookings') THEN
    RAISE NOTICE 'Bookings table exists. Checking schema...';
  ELSE
    RAISE EXCEPTION 'Bookings table does not exist! Create it first.';
  END IF;
END $$;

-- Ensure all required columns exist
-- Note: The ID field can be either UUID or TEXT depending on your existing schema
-- The Flutter app's Booking model supports both

-- Add missing columns if they don't exist
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS qr_code TEXT,
  ADD COLUMN IF NOT EXISTS qr_generated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS qr_expiry TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS check_in_time TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS check_out_time TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS checked_in_by TEXT,
  ADD COLUMN IF NOT EXISTS checked_out_by TEXT,
  ADD COLUMN IF NOT EXISTS grace_period_minutes INTEGER DEFAULT 10,
  ADD COLUMN IF NOT EXISTS extra_minutes INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS extra_rate_per_minute NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS extra_amount NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS host_extra_decision TEXT,
  ADD COLUMN IF NOT EXISTS final_amount NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
  ADD COLUMN IF NOT EXISTS expiry_reason TEXT;

-- Ensure original_amount column exists (for discount tracking)
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS original_amount NUMERIC(10,2) DEFAULT 0;

-- Ensure discount columns exist
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_percent NUMERIC(10,2) DEFAULT 0;

-- Ensure platform_fee exists
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS platform_fee NUMERIC(10,2) DEFAULT 9.00;

-- Update existing rows to set original_amount if null
UPDATE public.bookings
SET original_amount = base_amount
WHERE original_amount IS NULL OR original_amount = 0;

-- Create index on booking_status for faster queries
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(booking_status);
CREATE INDEX IF NOT EXISTS idx_bookings_renter_id ON public.bookings(renter_id);
CREATE INDEX IF NOT EXISTS idx_bookings_listing_id ON public.bookings(listing_id);
CREATE INDEX IF NOT EXISTS idx_bookings_booking_date ON public.bookings(booking_date);

-- Verify the schema
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bookings'
ORDER BY ordinal_position;

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Check sample booking with all fields
SELECT
  id,
  listing_id,
  renter_id,
  host_id,
  vehicle_type,
  booking_date,
  requested_entry_time,
  requested_exit_time,
  duration_hours,
  original_amount,
  discount_amount,
  discount_percent,
  base_amount,
  platform_fee,
  payment_status,
  booking_status,
  qr_code IS NOT NULL as has_qr_code,
  created_at
FROM public.bookings
ORDER BY created_at DESC
LIMIT 1;

-- Count bookings by status
SELECT
  booking_status,
  COUNT(*) as count
FROM public.bookings
GROUP BY booking_status
ORDER BY count DESC;

RAISE NOTICE 'Schema update complete! Check the results above.';
