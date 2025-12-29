-- ================================================================
-- PARKING APP - DUAL ROLE DATABASE SETUP (Renter + Host Apps)
-- ================================================================
-- This script sets up the database for BOTH renter and host apps
-- Run this in your Supabase SQL Editor
-- ================================================================

-- ================================================================
-- 1. UPDATE PROFILES TABLE WITH DUAL ROLES
-- ================================================================

-- Add new columns if they don't exist
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_renter BOOLEAN DEFAULT FALSE;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_host BOOLEAN DEFAULT FALSE;

-- Make role column nullable (legacy field)
ALTER TABLE public.profiles
ALTER COLUMN role DROP NOT NULL;

-- Update existing users to have proper structure
UPDATE public.profiles
SET is_renter = FALSE, is_host = FALSE
WHERE is_renter IS NULL OR is_host IS NULL;

-- ================================================================
-- 2. UPDATE TRIGGER TO NOT SET ROLE
-- ================================================================

-- Update the handle_new_user function to not set role
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, is_renter, is_host)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
    NEW.email,
    FALSE,  -- Will be set by respective app (renter/host)
    FALSE   -- Will be set by respective app (renter/host)
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================================
-- 3. UPDATE RLS POLICIES
-- ================================================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- Create new policies
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ================================================================
-- 4. ADD HELPFUL INDEXES
-- ================================================================

CREATE INDEX IF NOT EXISTS profiles_is_renter_idx ON public.profiles(is_renter);
CREATE INDEX IF NOT EXISTS profiles_is_host_idx ON public.profiles(is_host);

-- ================================================================
-- 5. ADD TABLE COMMENTS
-- ================================================================

COMMENT ON COLUMN public.profiles.role IS 'Legacy role field (nullable, can be ignored)';
COMMENT ON COLUMN public.profiles.is_renter IS 'TRUE when user uses RENTER app';
COMMENT ON COLUMN public.profiles.is_host IS 'TRUE when user uses HOST app';

-- ================================================================
-- SETUP COMPLETE!
-- ================================================================
-- Users can now:
-- - Use RENTER app → is_renter=TRUE
-- - Use HOST app → is_host=TRUE
-- - Use BOTH apps → Both flags TRUE
-- ================================================================

SELECT 'Dual role setup complete!' AS status;
