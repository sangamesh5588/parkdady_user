# Database Schema Documentation

This document describes the complete database schema for the Parking App, including all tables, relationships, and business logic.

## 🏗️ Database Architecture

### Core Tables Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   profiles      │    │ parking_spaces  │    │    bookings     │
│                 │    │                 │    │                 │
│ - id (uuid)     │◄───┤ - host_id (uuid) │    │ - id (text)     │
│ - role          │    │ - name          │    │ - user_id (uuid)│
│ - full_name     │    │ - address       │    │ - parking_space │
│ - phone         │    │ - price_per_hour│    │ - start_time    │
│ - permissions   │    │ - amenities     │    │ - end_time      │
└─────────────────┘    │ - images        │    │ - total_amount  │
                       │ - availability  │    │ - payment_id    │
                       └─────────────────┘    │ - qr_code_data  │
                                              │ - booking_status│
┌─────────────────┐    ┌─────────────────┐    └─────────────────┘
│    reviews      │    │   amenities     │
│                 │    │   (enum)        │
│ - booking_id    │    │                 │
│ - user_id       │    │ - covered       │
│ - rating        │    │ - security      │
│ - comment       │    │ - ev_charging   │
│ - is_verified   │    │ - valet         │
└─────────────────┘    └─────────────────┘
```

## 📋 Table Specifications

### 1. profiles Table

**Purpose:** User profile information and role management

```sql
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  phone text,
  role text DEFAULT 'renter' CHECK (role IN ('host', 'renter')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  onboarding_completed boolean DEFAULT false,
  permissions_granted jsonb DEFAULT '{}'::jsonb
);
```

**Key Features:**
- Automatic profile creation on user signup
- Role-based access control (host/renter)
- JSON permissions for granular access control

### 2. parking_spaces Table

**Purpose:** Parking space listings managed by hosts

```sql
CREATE TABLE public.parking_spaces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  address text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  zip_code text,
  latitude decimal(10,8),
  longitude decimal(11,8),
  price_per_hour decimal(10,2) NOT NULL CHECK (price_per_hour > 0),
  total_spaces integer NOT NULL CHECK (total_spaces > 0),
  available_spaces integer NOT NULL CHECK (available_spaces >= 0),
  amenities jsonb DEFAULT '[]'::jsonb,
  images jsonb DEFAULT '[]'::jsonb,
  rules text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

**Key Features:**
- GPS coordinates for mapping
- Dynamic availability tracking
- JSON arrays for flexible amenities and images
- Active/inactive status for management

### 3. bookings Table

**Purpose:** Parking space reservations and payment tracking

```sql
CREATE TABLE public.bookings (
  id text PRIMARY KEY, -- Format: BK-ABC123
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  parking_space_id uuid NOT NULL REFERENCES parking_spaces(id) ON DELETE CASCADE,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  duration_hours decimal(4,2) NOT NULL CHECK (duration_hours > 0),
  total_amount decimal(10,2) NOT NULL CHECK (total_amount > 0),
  vehicle_number text NOT NULL,
  vehicle_make text,
  vehicle_model text,
  vehicle_color text,
  booking_status booking_status DEFAULT 'pending',
  payment_status payment_status DEFAULT 'pending',
  payment_id text, -- Razorpay payment ID
  payment_order_id text, -- Razorpay order ID
  qr_code_data text, -- Encrypted QR validation data
  qr_valid_until timestamptz, -- QR expiration (2 hours after booking)
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  -- Constraints
  CHECK (end_time > start_time),
  EXCLUDE (parking_space_id WITH =, tstzrange(start_time, end_time) WITH &&)
    WHERE (booking_status IN ('confirmed', 'active')),
  UNIQUE(parking_space_id, start_time, end_time)
);
```

**Key Features:**
- Human-readable booking IDs
- Automatic overlap prevention
- Payment integration tracking
- QR code validation system
- Vehicle information storage

### 4. reviews Table

**Purpose:** User reviews and ratings for parking spaces

```sql
CREATE TABLE public.reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id text NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  parking_space_id uuid NOT NULL REFERENCES parking_spaces(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title text,
  comment text,
  cleanliness_rating integer CHECK (cleanliness_rating >= 1 AND cleanliness_rating <= 5),
  security_rating integer CHECK (security_rating >= 1 AND security_rating <= 5),
  location_rating integer CHECK (location_rating >= 1 AND location_rating <= 5),
  value_rating integer CHECK (value_rating >= 1 AND value_rating <= 5),
  is_recommended boolean,
  is_verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  -- Constraints
  UNIQUE(booking_id), -- One review per booking
  UNIQUE(user_id, parking_space_id) -- One review per user per space
);
```

**Key Features:**
- Multi-dimensional ratings (cleanliness, security, location, value)
- Verified reviews (only after booking completion)
- Recommendation tracking
- One review per booking and per user/space

## 🔐 Security & Access Control

### Row Level Security (RLS) Policies

#### Profiles
- Users can only access their own profile
- Automatic profile creation on signup

#### Parking Spaces
- Hosts can manage their own spaces
- Public read access for active listings
- Location-based browsing enabled

#### Bookings
- Users can access their own bookings
- Hosts can view bookings for their spaces
- Secure payment data handling

#### Reviews
- Public read access for all reviews
- Users can only review completed bookings
- Verified review system

## ⚡ Business Logic & Automation

### Triggers & Functions

#### 1. Automatic Availability Updates
```sql
-- Updates available_spaces when bookings are created/cancelled
CREATE TRIGGER update_parking_availability_trigger
  AFTER INSERT OR UPDATE OR DELETE ON bookings
  FOR EACH ROW EXECUTE PROCEDURE update_parking_availability();
```

#### 2. Booking ID Generation
```sql
-- Generates unique booking IDs like 'BK-ABC123'
CREATE FUNCTION generate_booking_id() RETURNS text
```

#### 3. Review Verification
```sql
-- Marks reviews as verified when booking completes
CREATE TRIGGER verify_reviews_on_completion_trigger
  AFTER UPDATE ON bookings
  FOR EACH ROW EXECUTE PROCEDURE verify_reviews_on_booking_completion();
```

#### 4. QR Code Expiration
- QR codes valid for 2 hours after booking ends
- Automatic cleanup prevents reuse

## 📊 Performance Optimizations

### Indexes Created

#### Parking Spaces
- `host_id` - Host-specific queries
- `city, state` - Location-based search
- `latitude, longitude` - Spatial queries (PostGIS)
- `is_active` - Active listing filters

#### Bookings
- `user_id` - User's booking history
- `parking_space_id` - Space availability
- `booking_status` - Status-based filtering
- `start_time, end_time` - Time-based queries
- Time range exclusion constraints

#### Reviews
- `parking_space_id` - Space ratings
- `rating` - Rating-based sorting

## 🔄 API Integration Points

### Core Endpoints

#### Parking Spaces
```typescript
GET    /api/parking-spaces        // List active spaces
GET    /api/parking-spaces/:id    // Get space details
POST   /api/parking-spaces        // Create new space (hosts only)
PUT    /api/parking-spaces/:id    // Update space (host only)
DELETE /api/parking-spaces/:id    // Deactivate space (host only)
```

#### Bookings
```typescript
GET    /api/bookings              // User's active bookings
GET    /api/bookings/history      // User's past bookings
POST   /api/bookings              // Create new booking
PUT    /api/bookings/:id          // Update booking status
GET    /api/bookings/:id/qr       // Get QR code data
POST   /api/bookings/:id/validate // Validate QR code
```

#### Reviews
```typescript
GET    /api/reviews/:spaceId      // Get reviews for space
POST   /api/reviews               // Create new review
PUT    /api/reviews/:id           // Update review
DELETE /api/reviews/:id           // Delete review
```

### Payment Integration

#### Razorpay Webhooks
```typescript
POST /api/webhooks/razorpay
// Handles payment success/failure
// Updates booking and payment status
// Generates QR codes on success
```

## 📈 Data Flow

### Booking Creation Process

1. **User selects parking space** → Check availability
2. **Choose date/time** → Validate no overlaps
3. **Enter vehicle details** → Store for QR validation
4. **Payment processing** → Razorpay integration
5. **Booking confirmation** → Status: confirmed
6. **QR code generation** → Encrypted validation data
7. **Check-in validation** → QR scanning at entrance

### Review System

1. **Booking completion** → Trigger verification
2. **Review submission** → Multi-dimensional ratings
3. **Verification badge** → Shows completed booking
4. **Public display** → Helps other users decide

## 🧪 Testing & Sample Data

### Sample Data Insertion

```sql
-- Insert sample parking spaces
INSERT INTO parking_spaces (
  host_id, name, address, city, state,
  price_per_hour, total_spaces, available_spaces,
  amenities, is_active
) VALUES (...);

-- Insert sample bookings
INSERT INTO bookings (
  id, user_id, parking_space_id, start_time, end_time,
  total_amount, vehicle_number, booking_status, payment_status
) VALUES (...);
```

### Test Scenarios

1. **Booking Overlap Prevention**
2. **Availability Auto-Updates**
3. **QR Code Expiration**
4. **Review Verification**
5. **Payment Status Tracking**

## 🚀 Production Deployment

### Pre-deployment Checklist

1. **Remove sample data** from schema file
2. **Enable PostGIS extension** for spatial queries
3. **Configure backup policies** for critical data
4. **Set up monitoring** for booking/payment flows
5. **Test all RLS policies** with different user roles
6. **Verify payment webhooks** are working
7. **Set up database indexes** for performance

### Scaling Considerations

1. **Partition bookings table** by date ranges
2. **Archive old bookings** after 2 years
3. **Implement caching** for popular parking spaces
4. **Use read replicas** for review aggregations
5. **Monitor query performance** and optimize slow queries

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://postgresql.org/docs)
- [PostGIS Documentation](https://postgis.net/docs)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

---

**🎉 Your database schema is production-ready with comprehensive booking and review functionality!**
