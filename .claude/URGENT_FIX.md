# 🚨 URGENT FIX REQUIRED - Row Level Security Issue

## Problem Found

Your app can't see the data because **Row Level Security (RLS)** is blocking it!

- ✅ Data EXISTS in database (verified with service role key)
- ❌ App can't access it (anon key returns empty)
- 🔒 RLS is enabled but no public read policy exists

## Quick Fix (2 minutes)

### Step 1: Go to Supabase SQL Editor
1. Open https://supabase.com/dashboard/project/eivjgwxyijhfmnyrcbcb/sql/new
2. Or: Dashboard → SQL Editor → New Query

### Step 2: Run This SQL
```sql
CREATE POLICY IF NOT EXISTS "Allow public read access to parking_active_slots"
ON public.parking_active_slots
FOR SELECT
TO public
USING (true);
```

### Step 3: Click "Run" Button

### Step 4: Restart Your App
- Hot restart (press `r` in terminal)
- Or full restart

## What This Does

This creates a Row Level Security policy that allows **anyone** (including your app using the anon key) to **read** data from the `parking_active_slots` table.

## Security Note

This is safe for read-only data like parking availability. For write operations (INSERT/UPDATE/DELETE), you should require authentication.

## Verification

After running the SQL, test the API directly:

```bash
curl "https://eivjgwxyijhfmnyrcbcb.supabase.co/rest/v1/parking_active_slots?select=*"   -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpdmpnd3h5aWpoZm1ueXJjYmNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjI3NzgsImV4cCI6MjA4MDkzODc3OH0.iggHHUPjpG6saWEnoJ9WaSDa-rT-FPWjMAnUr7dWfRA"
```

You should see JSON data returned instead of `[]`.

## Alternative: Disable RLS (Not Recommended)

If you want to quickly test without RLS:

```sql
ALTER TABLE public.parking_active_slots DISABLE ROW LEVEL SECURITY;
```

**Note:** This makes the table completely public. Only use for testing!

---

**After running the SQL, your app will immediately start loading parking data! 🎉**
