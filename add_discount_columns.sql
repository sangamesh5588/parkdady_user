-- Add discount columns to listings table for hourly and daily rates
-- Supports both car and bike discounts

-- Add hourly discount columns (flat amount)
ALTER TABLE public.listings
ADD COLUMN IF NOT EXISTS hourly_discount_car NUMERIC(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS hourly_discount_bike NUMERIC(10, 2) DEFAULT 0;

-- Add daily discount columns (flat amount)
ALTER TABLE public.listings
ADD COLUMN IF NOT EXISTS daily_discount_car NUMERIC(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS daily_discount_bike NUMERIC(10, 2) DEFAULT 0;

-- Add hourly discount percentage columns
ALTER TABLE public.listings
ADD COLUMN IF NOT EXISTS hourly_discount_car_percent NUMERIC(5, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS hourly_discount_bike_percent NUMERIC(5, 2) DEFAULT 0;

-- Add daily discount percentage columns
ALTER TABLE public.listings
ADD COLUMN IF NOT EXISTS daily_discount_car_percent NUMERIC(5, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS daily_discount_bike_percent NUMERIC(5, 2) DEFAULT 0;

-- Add comments for documentation
COMMENT ON COLUMN public.listings.hourly_discount_car IS 'Hourly discount amount in rupees for car parking';
COMMENT ON COLUMN public.listings.hourly_discount_bike IS 'Hourly discount amount in rupees for bike parking';
COMMENT ON COLUMN public.listings.daily_discount_car IS 'Daily discount amount in rupees for car parking';
COMMENT ON COLUMN public.listings.daily_discount_bike IS 'Daily discount amount in rupees for bike parking';
COMMENT ON COLUMN public.listings.hourly_discount_car_percent IS 'Hourly discount percentage (0-100) for car parking';
COMMENT ON COLUMN public.listings.hourly_discount_bike_percent IS 'Hourly discount percentage (0-100) for bike parking';
COMMENT ON COLUMN public.listings.daily_discount_car_percent IS 'Daily discount percentage (0-100) for car parking';
COMMENT ON COLUMN public.listings.daily_discount_bike_percent IS 'Daily discount percentage (0-100) for bike parking';

-- Add constraints to ensure percentage is between 0 and 100
ALTER TABLE public.listings
ADD CONSTRAINT IF NOT EXISTS check_hourly_discount_car_percent
  CHECK (hourly_discount_car_percent >= 0 AND hourly_discount_car_percent <= 100);

ALTER TABLE public.listings
ADD CONSTRAINT IF NOT EXISTS check_hourly_discount_bike_percent
  CHECK (hourly_discount_bike_percent >= 0 AND hourly_discount_bike_percent <= 100);

ALTER TABLE public.listings
ADD CONSTRAINT IF NOT EXISTS check_daily_discount_car_percent
  CHECK (daily_discount_car_percent >= 0 AND daily_discount_car_percent <= 100);

ALTER TABLE public.listings
ADD CONSTRAINT IF NOT EXISTS check_daily_discount_bike_percent
  CHECK (daily_discount_bike_percent >= 0 AND daily_discount_bike_percent <= 100);

-- Add discount validity period (optional)
ALTER TABLE public.listings
ADD COLUMN IF NOT EXISTS discount_valid_from TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS discount_valid_until TIMESTAMPTZ;

COMMENT ON COLUMN public.listings.discount_valid_from IS 'Discount valid from this date/time';
COMMENT ON COLUMN public.listings.discount_valid_until IS 'Discount valid until this date/time';

-- Example usage:
-- Flat discount: hourly_rate_car = 50, hourly_discount_car = 10 → Final price = 40
-- Percentage discount: hourly_rate_car = 50, hourly_discount_car_percent = 20 → Final price = 40
-- Both: Apply flat discount first, then percentage on the result
