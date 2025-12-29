-- Add discount columns to the listings table
-- This allows hosts to set discounted prices for cars and bikes

-- Add discount columns
ALTER TABLE public.listings
ADD COLUMN IF NOT EXISTS discount_car NUMERIC(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS discount_bike NUMERIC(10, 2) DEFAULT 0;

-- Add comments to explain the columns
COMMENT ON COLUMN public.listings.discount_car IS 'Discount amount in rupees for car parking';
COMMENT ON COLUMN public.listings.discount_bike IS 'Discount amount in rupees for bike parking';

-- Example: If hourly_rate_car is 50 and discount_car is 10, final price will be 40

-- You can also add percentage-based discount columns if needed
ALTER TABLE public.listings
ADD COLUMN IF NOT EXISTS discount_car_percentage NUMERIC(5, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS discount_bike_percentage NUMERIC(5, 2) DEFAULT 0;

COMMENT ON COLUMN public.listings.discount_car_percentage IS 'Discount percentage for car parking (0-100)';
COMMENT ON COLUMN public.listings.discount_bike_percentage IS 'Discount percentage for bike parking (0-100)';

-- Add a discount validity period (optional)
ALTER TABLE public.listings
ADD COLUMN IF NOT EXISTS discount_valid_until TIMESTAMPTZ;

COMMENT ON COLUMN public.listings.discount_valid_until IS 'Discount valid until this date/time';

-- Add constraint to ensure discount percentage is between 0 and 100
ALTER TABLE public.listings
ADD CONSTRAINT check_discount_car_percentage CHECK (discount_car_percentage >= 0 AND discount_car_percentage <= 100),
ADD CONSTRAINT check_discount_bike_percentage CHECK (discount_bike_percentage >= 0 AND discount_bike_percentage <= 100);

-- Sample update to set discounts (for testing)
-- UPDATE public.listings
-- SET discount_car = 10, discount_bike = 5
-- WHERE id = 'your-listing-id';
