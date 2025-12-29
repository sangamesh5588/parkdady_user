-- ================================================================
-- DATABASE STATUS CHECK
-- Run this to see current state of bookings table
-- ================================================================

-- 1. Check if bookings table exists
SELECT
  CASE
    WHEN EXISTS (
      SELECT FROM pg_tables
      WHERE schemaname = 'public'
      AND tablename = 'bookings'
    ) THEN '✅ Bookings table EXISTS'
    ELSE '❌ Bookings table DOES NOT EXIST - Run recreate_bookings_table.sql first!'
  END as table_status;

-- 2. If table exists, check its columns
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bookings'
ORDER BY ordinal_position;

-- 3. Check RLS policies
SELECT
  policyname,
  cmd,
  CASE
    WHEN qual IS NOT NULL THEN 'Has USING clause'
    ELSE 'No USING clause'
  END as has_qual,
  CASE
    WHEN with_check IS NOT NULL THEN 'Has WITH CHECK clause'
    ELSE 'No WITH CHECK clause'
  END as has_with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'bookings';

-- 4. Check current bookings count
SELECT COUNT(*) as total_bookings FROM public.bookings;

-- 5. Check if user can insert (test authentication)
SELECT
  auth.uid() as current_user_id,
  CASE
    WHEN auth.uid() IS NOT NULL THEN '✅ User is authenticated'
    ELSE '❌ User is NOT authenticated'
  END as auth_status;

-- 6. Try to get user details
SELECT
  id,
  email,
  created_at
FROM auth.users
WHERE id = auth.uid();
