# Parking App - Database Setup Guide

## 🚀 Quick Start

### 1. Execute Database Schema
Before running the app, you need to set up the database schema:

1. **Open your Supabase Dashboard**
2. **Go to SQL Editor**
3. **Copy and paste the entire contents of `database_setup.sql`**
4. **Click "Run" to execute the schema**

This will create:
- `profiles` table with proper structure
- Automatic profile creation trigger for new users
- Row Level Security policies
- Default 'renter' role for all users

### 2. Environment Setup
Make sure your `.env` file contains:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 3. Google Maps Setup
To enable map functionality, you need to get a Google Maps API key:

1. **Get API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable **Maps SDK for Android** and **Maps SDK for iOS**
   - Create credentials (API Key)

2. **Add API Key to Android**:
   - Open `android/app/src/main/AndroidManifest.xml`
   - Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key (line 68)

3. **Add API Key to iOS**:
   - Open `ios/Runner/AppDelegate.swift`
   - Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key (line 12)

### 4. Run the App
```bash
flutter pub get
flutter run
```

## 🔐 Authentication Flow

### User Registration (Signup)
1. User fills signup form
2. Supabase creates auth user
3. Database trigger automatically creates profile with `role = 'renter'`
4. App fetches profile and stores role in state

### User Login
1. User enters credentials
2. Supabase authenticates user
3. App fetches profile from database
4. Role is available throughout the app

### Role Management
- **All app users**: Default to 'renter' role
- **Host app**: Can update role to 'host' if needed
- **Renter app**: Only reads role, never updates

## 📊 Database Schema

```sql
-- Profiles table structure
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT,
  phone TEXT,
  role TEXT DEFAULT 'renter' CHECK (role IN ('host', 'renter')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  onboarding_completed BOOLEAN DEFAULT FALSE,
  permissions_granted JSONB DEFAULT '{}'
);
```

## 🛠️ Troubleshooting

### Profile Not Found Error
If you see profile-related errors:
1. **Check database schema**: Make sure `database_setup.sql` was executed
2. **Verify trigger**: The trigger should create profiles automatically
3. **Check permissions**: RLS policies should allow profile access

### Authentication Issues
- Ensure Supabase URL and keys are correct in `.env`
- Check Supabase project settings
- Verify email confirmation is set up (if required)

### Role Not Showing
- Profile must exist in database
- Check browser console for fetch errors
- Ensure user is authenticated before accessing profile

## 🔄 App Architecture

- **Database-driven roles**: No hardcoded assumptions
- **Automatic profile creation**: Trigger handles new users
- **Secure access**: RLS protects user data
- **Real-time updates**: Auth state changes trigger profile refetch

---

**Need help?** Check the console logs for detailed error messages.
"# parking_user_app"  
