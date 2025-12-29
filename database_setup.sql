-- Database setup for parking app profiles
-- This script creates the profiles table with proper constraints and triggers

-- Create the profiles table
create table public.profiles (
  id uuid not null,
  full_name text null,
  phone text null,
  role text null default 'renter'::text, -- Default role is 'renter' for all users
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  onboarding_completed boolean not null default false,
  permissions_granted jsonb null default '{}'::jsonb,
  constraint profiles_pkey primary key (id),
  constraint profiles_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE,
  constraint profiles_role_check check (
    (role = any (array['host'::text, 'renter'::text]))
  )
) TABLESPACE pg_default;

-- Create the function to update updated_at timestamp
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create the trigger to automatically update updated_at on row updates
create trigger update_profiles_updated_at BEFORE
update on profiles for EACH row
execute FUNCTION set_updated_at();

-- Create a function to automatically create profile with 'renter' role when user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    'renter'
  );
  return new;
end;
$$ language plpgsql;

-- Create trigger to automatically create profile for new users
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Enable Row Level Security (RLS) on profiles table
alter table public.profiles enable row level security;

-- Create policies so users can only see, update, and insert their own profiles
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

-- Grant necessary permissions
grant usage on schema public to anon, authenticated;
grant all on public.profiles to anon, authenticated;
grant all on public.profiles to service_role;

-- Optional: Create an index on role for better query performance
create index if not exists profiles_role_idx on public.profiles (role);

-- =====================================================================================
-- VEHICLES TABLE
-- =====================================================================================

-- Create vehicles table for user vehicle management
create table public.vehicles (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  license_plate text not null,
  make text not null,
  model text not null,
  color text,
  year integer,
  is_default boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint vehicles_license_plate_user_unique unique(user_id, license_plate),
  constraint vehicles_year_check check (year is null or (year >= 1900 and year <= extract(year from now()) + 1))
) tablespace pg_default;

-- Create indexes for vehicles table
create index if not exists vehicles_user_id_idx on public.vehicles (user_id);
create index if not exists vehicles_is_default_idx on public.vehicles (user_id, is_default) where is_default = true;

-- Create trigger for updated_at timestamp on vehicles
create trigger update_vehicles_updated_at before update on public.vehicles
  for each row execute procedure public.set_updated_at();

-- Function to ensure only one default vehicle per user
create or replace function public.ensure_single_default_vehicle()
returns trigger as $$
begin
  if new.is_default = true then
    -- Set all other vehicles for this user to not default
    update public.vehicles
    set is_default = false
    where user_id = new.user_id and id != new.id;
  end if;

  return new;
end;
$$ language plpgsql;

-- Trigger to ensure only one default vehicle per user
create trigger ensure_single_default_vehicle_trigger
  before insert or update on public.vehicles
  for each row execute procedure public.ensure_single_default_vehicle();

-- Enable RLS on vehicles table
alter table public.vehicles enable row level security;

-- Vehicles policies - users can only manage their own vehicles
create policy "Users can view own vehicles" on public.vehicles
  for select using (auth.uid() = user_id);

create policy "Users can insert own vehicles" on public.vehicles
  for insert with check (auth.uid() = user_id);

create policy "Users can update own vehicles" on public.vehicles
  for update using (auth.uid() = user_id);

create policy "Users can delete own vehicles" on public.vehicles
  for delete using (auth.uid() = user_id);

-- Grant permissions for vehicles table
grant all on public.vehicles to anon, authenticated;
grant all on public.vehicles to service_role;

-- =====================================================================================
-- PARKING SPACES, BOOKINGS, AND REVIEWS TABLES
-- =====================================================================================

-- Create enum for booking status
create type booking_status as enum ('pending', 'confirmed', 'active', 'completed', 'cancelled', 'expired');

-- Create enum for payment status
create type payment_status as enum ('pending', 'paid', 'failed', 'refunded');

-- Create parking_spaces table
create table public.parking_spaces (
  id uuid default gen_random_uuid() primary key,
  host_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  description text,
  address text not null,
  city text not null,
  state text not null,
  zip_code text,
  latitude decimal(10, 8),
  longitude decimal(11, 8),
  price_per_hour decimal(10, 2) not null check (price_per_hour > 0),
  total_spaces integer not null check (total_spaces > 0),
  available_spaces integer not null check (available_spaces >= 0 and available_spaces <= total_spaces),
  amenities jsonb default '[]'::jsonb, -- Array of amenities like ['covered', 'ev_charging', 'security']
  images jsonb default '[]'::jsonb, -- Array of image URLs
  rules text, -- Parking rules and instructions
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint parking_spaces_coordinates_check check (
    (latitude is null and longitude is null) or
    (latitude >= -90 and latitude <= 90 and longitude >= -180 and longitude <= 180)
  )
) tablespace pg_default;

-- Create bookings table
create table public.bookings (
  id text primary key, -- Using text ID like 'BK-ABC123' for readability
  user_id uuid not null references public.profiles(id) on delete cascade,
  parking_space_id uuid not null references public.parking_spaces(id) on delete cascade,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  duration_hours decimal(4, 2) not null check (duration_hours > 0),
  total_amount decimal(10, 2) not null check (total_amount > 0),
  vehicle_number text not null,
  vehicle_make text,
  vehicle_model text,
  vehicle_color text,
  booking_status booking_status default 'pending',
  payment_status payment_status default 'pending',
  payment_id text, -- Razorpay payment ID
  payment_order_id text, -- Razorpay order ID
  qr_code_data text, -- Encrypted QR code data for validation
  qr_valid_until timestamp with time zone, -- QR code expiration
  notes text, -- Special instructions or notes
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint bookings_time_check check (end_time > start_time),
  constraint bookings_no_overlap exclude (
    parking_space_id with =,
    tstzrange(start_time, end_time) with &&
  ) where (booking_status in ('confirmed', 'active')),
  unique(parking_space_id, start_time, end_time)
) tablespace pg_default;

-- Create reviews table
create table public.reviews (
  id uuid default gen_random_uuid() primary key,
  booking_id text not null references public.bookings(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  parking_space_id uuid not null references public.parking_spaces(id) on delete cascade,
  rating integer not null check (rating >= 1 and rating <= 5),
  title text,
  comment text,
  cleanliness_rating integer check (cleanliness_rating >= 1 and cleanliness_rating <= 5),
  security_rating integer check (security_rating >= 1 and security_rating <= 5),
  location_rating integer check (location_rating >= 1 and location_rating <= 5),
  value_rating integer check (value_rating >= 1 and value_rating <= 5),
  is_recommended boolean,
  is_verified boolean default false, -- Verified if booking was completed
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint reviews_unique_booking unique(booking_id), -- One review per booking
  constraint reviews_user_parking_unique unique(user_id, parking_space_id) -- One review per user per parking space
) tablespace pg_default;

-- Create indexes for better performance
create index if not exists parking_spaces_host_id_idx on public.parking_spaces (host_id);
create index if not exists parking_spaces_location_idx on public.parking_spaces using gist (point(longitude, latitude));
create index if not exists parking_spaces_city_state_idx on public.parking_spaces (city, state);
create index if not exists parking_spaces_is_active_idx on public.parking_spaces (is_active);

create index if not exists bookings_user_id_idx on public.bookings (user_id);
create index if not exists bookings_parking_space_id_idx on public.bookings (parking_space_id);
create index if not exists bookings_status_idx on public.bookings (booking_status);
create index if not exists bookings_payment_status_idx on public.bookings (payment_status);
create index if not exists bookings_start_time_idx on public.bookings (start_time);
create index if not exists bookings_end_time_idx on public.bookings (end_time);
create index if not exists bookings_time_range_idx on public.bookings using gist (tstzrange(start_time, end_time));

create index if not exists reviews_parking_space_id_idx on public.reviews (parking_space_id);
create index if not exists reviews_user_id_idx on public.reviews (user_id);
create index if not exists reviews_rating_idx on public.reviews (rating);

-- Create triggers for updated_at timestamps
create trigger update_parking_spaces_updated_at before update on public.parking_spaces
  for each row execute procedure public.set_updated_at();

create trigger update_bookings_updated_at before update on public.bookings
  for each row execute procedure public.set_updated_at();

create trigger update_reviews_updated_at before update on public.reviews
  for each row execute procedure public.set_updated_at();

-- =====================================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================================================

-- Enable RLS on all new tables
alter table public.parking_spaces enable row level security;
alter table public.bookings enable row level security;
alter table public.reviews enable row level security;

-- Parking spaces policies
-- Hosts can manage their own parking spaces
create policy "Hosts can view own parking spaces" on public.parking_spaces
  for select using (auth.uid() = host_id);

create policy "Hosts can insert own parking spaces" on public.parking_spaces
  for insert with check (auth.uid() = host_id);

create policy "Hosts can update own parking spaces" on public.parking_spaces
  for update using (auth.uid() = host_id);

create policy "Hosts can delete own parking spaces" on public.parking_spaces
  for delete using (auth.uid() = host_id);

-- Everyone can view active parking spaces for browsing
create policy "Everyone can view active parking spaces" on public.parking_spaces
  for select using (is_active = true);

-- Bookings policies
-- Users can view their own bookings
create policy "Users can view own bookings" on public.bookings
  for select using (auth.uid() = user_id);

create policy "Users can insert own bookings" on public.bookings
  for insert with check (auth.uid() = user_id);

create policy "Users can update own bookings" on public.bookings
  for update using (auth.uid() = user_id);

-- Hosts can view bookings for their parking spaces
create policy "Hosts can view bookings for own spaces" on public.bookings
  for select using (
    exists (
      select 1 from public.parking_spaces
      where id = parking_space_id and host_id = auth.uid()
    )
  );

-- Reviews policies
-- Everyone can view reviews
create policy "Everyone can view reviews" on public.reviews
  for select using (true);

-- Users can insert reviews for their completed bookings
create policy "Users can insert reviews for own bookings" on public.reviews
  for insert with check (
    auth.uid() = user_id and
    exists (
      select 1 from public.bookings
      where id = booking_id and user_id = auth.uid()
      and booking_status = 'completed'
    )
  );

-- Users can update their own reviews
create policy "Users can update own reviews" on public.reviews
  for update using (auth.uid() = user_id);

-- =====================================================================================
-- FUNCTIONS AND TRIGGERS FOR BUSINESS LOGIC
-- =====================================================================================

-- Function to generate booking ID
create or replace function public.generate_booking_id()
returns text as $$
declare
  booking_id text;
  counter integer := 0;
begin
  loop
    booking_id := 'BK-' || upper(substring(gen_random_uuid()::text, 1, 6));
    exit when not exists (select 1 from public.bookings where id = booking_id);
    counter := counter + 1;
    if counter > 10 then
      raise exception 'Could not generate unique booking ID';
    end if;
  end loop;
  return booking_id;
end;
$$ language plpgsql;

-- Function to update parking space availability
create or replace function public.update_parking_availability()
returns trigger as $$
begin
  -- Update available spaces based on confirmed/active bookings
  if tg_op = 'INSERT' and new.booking_status in ('confirmed', 'active') then
    update public.parking_spaces
    set available_spaces = available_spaces - 1
    where id = new.parking_space_id and available_spaces > 0;
  elsif tg_op = 'UPDATE' then
    -- Restore space if booking is cancelled or completed
    if old.booking_status in ('confirmed', 'active') and
       new.booking_status not in ('confirmed', 'active') then
      update public.parking_spaces
      set available_spaces = available_spaces + 1
      where id = new.parking_space_id;
    end if;
    -- Reduce space if status changed to confirmed/active
    if old.booking_status not in ('confirmed', 'active') and
       new.booking_status in ('confirmed', 'active') then
      update public.parking_spaces
      set available_spaces = available_spaces - 1
      where id = new.parking_space_id and available_spaces > 0;
    end if;
  elsif tg_op = 'DELETE' and old.booking_status in ('confirmed', 'active') then
    update public.parking_spaces
    set available_spaces = available_spaces + 1
    where id = old.parking_space_id;
  end if;

  return coalesce(new, old);
end;
$$ language plpgsql;

-- Trigger to update parking availability when bookings change
create trigger update_parking_availability_trigger
  after insert or update or delete on public.bookings
  for each row execute procedure public.update_parking_availability();

-- Function to automatically set booking ID and QR data
create or replace function public.set_booking_defaults()
returns trigger as $$
begin
  -- Set booking ID if not provided
  if new.id is null or new.id = '' then
    new.id := public.generate_booking_id();
  end if;

  -- Calculate duration in hours
  new.duration_hours := extract(epoch from (new.end_time - new.start_time)) / 3600;

  -- Generate QR code data (will be populated by application)
  -- new.qr_code_data := ... (handled by application)

  -- Set QR valid until (2 hours after booking ends)
  new.qr_valid_until := new.end_time + interval '2 hours';

  return new;
end;
$$ language plpgsql;

-- Trigger to set booking defaults
create trigger set_booking_defaults_trigger
  before insert on public.bookings
  for each row execute procedure public.set_booking_defaults();

-- Function to mark reviews as verified when booking is completed
create or replace function public.verify_reviews_on_booking_completion()
returns trigger as $$
begin
  if new.booking_status = 'completed' and old.booking_status != 'completed' then
    update public.reviews
    set is_verified = true
    where booking_id = new.id;
  end if;

  return new;
end;
$$ language plpgsql;

-- Trigger to verify reviews when booking is completed
create trigger verify_reviews_on_completion_trigger
  after update on public.bookings
  for each row execute procedure public.verify_reviews_on_booking_completion();

-- =====================================================================================
-- GRANT PERMISSIONS
-- =====================================================================================

-- Grant permissions for all tables
grant usage on schema public to anon, authenticated;
grant all on public.parking_spaces to anon, authenticated;
grant all on public.bookings to anon, authenticated;
grant all on public.reviews to anon, authenticated;
grant all on public.parking_spaces to service_role;
grant all on public.bookings to service_role;
grant all on public.reviews to service_role;

-- =====================================================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================================================

-- Note: Remove this section in production
-- Insert sample parking spaces (uncomment to add test data)
/*
insert into public.parking_spaces (
  host_id, name, description, address, city, state, price_per_hour,
  total_spaces, available_spaces, amenities, images, is_active
) values
(
  (select id from public.profiles limit 1),
  'Downtown Parking Garage',
  'Secure covered parking in the heart of downtown',
  '123 Main St, Downtown',
  'New York',
  'NY',
  15.00,
  50,
  45,
  '["covered", "security", "ev_charging"]'::jsonb,
  '["https://example.com/image1.jpg"]'::jsonb,
  true
),
(
  (select id from public.profiles limit 1),
  'Central Mall Parking',
  'Convenient parking for mall shoppers',
  '456 Commerce Blvd, Midtown',
  'New York',
  'NY',
  12.00,
  100,
  95,
  '["covered", "security"]'::jsonb,
  '["https://example.com/image2.jpg"]'::jsonb,
  true
);
*/
