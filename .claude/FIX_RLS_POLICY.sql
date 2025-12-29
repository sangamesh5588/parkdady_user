-- ⚠️ IMPORTANT: Run this SQL in Supabase SQL Editor to fix data loading
-- This enables public read access to parking_active_slots table

-- Create policy to allow anyone to read parking_active_slots
CREATE POLICY IF NOT EXISTS "Allow public read access to parking_active_slots"
ON public.parking_active_slots
FOR SELECT
TO public
USING (true);

-- Verify the policy was created
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'parking_active_slots';
