# 🚀 Parking App - Complete Setup Guide

## Overview
This is a complete, clean authentication system for the Parking App built with Flutter and Supabase. All users who sign up through the app are automatically assigned the **'renter'** role.

---

## 📋 Prerequisites

- Flutter SDK installed (3.0+)
- Supabase account ([https://supabase.com](https://supabase.com))
- Android Studio / VS Code with Flutter extensions
- Android emulator or physical device

---

## 🔧 Step 1: Supabase Project Setup

### 1.1 Create Supabase Project
1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Fill in:
   - Project name: `parking-app` (or your preferred name)
   - Database password: (create a strong password)
   - Region: Choose closest to you
4. Click "Create new project" and wait for initialization

### 1.2 Get API Credentials
1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy these values:
   - **Project URL** (looks like: `https://xxxxxxxxxxxxx.supabase.co`)
   - **anon public key** (long JWT token)

### 1.3 Set up Database
1. In Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Open the file `supabase_setup.sql` from your project
4. Copy and paste the **entire SQL script** into the SQL editor
5. Click "Run" or press `Ctrl+Enter` / `Cmd+Enter`
6. Wait for "Success" message

**What this does:**
- Creates `profiles` table
- Sets up automatic profile creation when users sign up
- Configures Row Level Security (RLS)
- Creates database triggers
- All users get `role='renter'` by default

### 1.4 Enable Email Auth (Important!)
1. Go to **Authentication** → **Providers**
2. Make sure **Email** is enabled
3. **Recommended:** Disable "Confirm email" for testing:
   - Go to **Authentication** → **Settings**
   - Under "Email Auth", toggle off "Enable email confirmations"
   - This lets you test without email verification

### 1.5 (Optional) Setup OAuth
For Google/Apple sign-in:
1. Go to **Authentication** → **Providers**
2. Enable **Google** and/or **Apple**
3. Follow Supabase's guides to configure each provider
4. Add redirect URLs: `io.supabase.parkingapp://login-callback`

---

## 💻 Step 2: Flutter App Setup

### 2.1 Update Environment Variables
1. Open the `.env` file in your project root
2. Replace with your Supabase credentials:
   ```env
   SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
   SUPABASE_ANON_KEY=YOUR_ANON_PUBLIC_KEY

   APP_NAME=Parking App
   APP_VERSION=1.0.0
   ```

### 2.2 Install Dependencies
Open terminal in project folder and run:
```bash
flutter pub get
```

This installs:
- `supabase_flutter` - Supabase client
- `flutter_riverpod` - State management
- `flutter_dotenv` - Environment variables
- `font_awesome_flutter` - Icons

### 2.3 Clean and Build
```bash
flutter clean
flutter pub get
```

---

## ▶️ Step 3: Run the App

### 3.1 Start Your Device/Emulator
- **Android Emulator**: Start from Android Studio
- **Physical Device**: Connect via USB with debugging enabled
- Check device: `flutter devices`

### 3.2 Run the App
```bash
flutter run
```

**First Run:**
- App will initialize Supabase
- You'll see the Login screen
- This means everything is working!

---

## 🧪 Step 4: Test Authentication

### Test 1: Email Signup
1. On login screen, tap "Sign Up"
2. Fill in the signup form:
   - Full Name: `Test User`
   - Email: `test@example.com`
   - Password: `test1234` (min 6 characters)
   - Confirm Password: `test1234`
   - Check "I agree to terms"
3. Tap "Create Account"
4. **Expected result:**
   - Success message appears
   - You're redirected to login screen
   - If email confirmation is enabled, check your email

### Test 2: Email Login
1. On login screen, enter:
   - Email: `test@example.com`
   - Password: `test1234`
2. Tap "Sign In"
3. **Expected result:**
   - You're logged in
   - Home screen appears

### Test 3: Verify Database
1. Go to Supabase dashboard → **Table Editor** → `profiles`
2. You should see your new user with:
   - `id`: UUID
   - `full_name`: "Test User"
   - `role`: **"renter"** ✓
   - `created_at`: timestamp

### Test 4: Forgot Password (Optional)
1. On login screen, enter your email
2. Tap "Forgot password?"
3. Check your email for reset link

### Test 5: Google/Apple Sign In (If configured)
1. Tap "Continue with Google" or "Continue with Apple"
2. Follow OAuth flow
3. Profile should be auto-created with role='renter'

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── colors.dart              # App color scheme
│   ├── constants.dart           # App constants
│   └── supabase_config.dart     # Supabase initialization
├── domain/
│   └── entities/
│       └── user.dart            # User model with role
├── services/
│   └── auth_service.dart        # NEW: Clean auth service
├── providers/
│   └── auth_provider.dart       # NEW: Riverpod auth state
├── screens/
│   ├── login_screen.dart        # NEW: Clean login UI
│   └── signup_screen.dart       # NEW: Clean signup UI
├── presentation/
│   ├── pages/
│   │   └── home/
│   │       └── home_screen.dart # Home after login
│   └── widgets/
│       ├── custom_button.dart
│       └── custom_text_field.dart
└── main.dart                    # UPDATED: App entry point
```

---

## 🔐 How Authentication Works

### Signup Flow:
```
1. User fills signup form
   ↓
2. App calls AuthService.signUpWithEmail()
   ↓
3. Supabase creates user in auth.users table
   ↓
4. Database trigger "on_auth_user_created" fires automatically
   ↓
5. Trigger creates profile record:
   - id: user's UUID
   - full_name: from signup form
   - role: 'renter' (DEFAULT)
   ↓
6. AuthProvider fetches profile from database
   ↓
7. User object created with role='renter'
   ↓
8. User is authenticated and redirected
```

### Login Flow:
```
1. User enters credentials
   ↓
2. App calls AuthService.signInWithEmail()
   ↓
3. Supabase validates credentials
   ↓
4. AuthProvider fetches user profile (including role)
   ↓
5. User state updated with role='renter'
   ↓
6. AuthWrapper detects authentication
   ↓
7. User redirected to HomeScreen
```

---

## 🐛 Troubleshooting

### Issue: "Configuration Error" on app start
**Cause:** Supabase credentials not configured
**Solution:**
1. Check `.env` file exists and has correct values
2. Run `flutter clean && flutter pub get`
3. Make sure `.env` is in project root (same folder as `pubspec.yaml`)

### Issue: "Signup failed: User already registered"
**Cause:** Email already exists in database
**Solution:**
1. Use a different email, OR
2. Delete user from Supabase: **Authentication** → **Users** → Delete user

### Issue: "Profile not found" or null role
**Cause:** Database trigger didn't create profile
**Solution:**
1. Check if `supabase_setup.sql` was run correctly
2. Go to **SQL Editor** and verify trigger exists:
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
   ```
3. Re-run the setup script if needed

### Issue: "Email not confirmed" error
**Cause:** Email confirmation required
**Solution:**
1. Check email inbox for verification link, OR
2. Disable email confirmation in Supabase:
   - **Authentication** → **Settings**
   - Toggle off "Enable email confirmations"

### Issue: Can't login after signup
**Cause:** Email verification required
**Solution:**
- Check your email and click verification link
- Wait a few seconds and try again

### Issue: OAuth not working
**Cause:** OAuth not configured
**Solution:**
1. Follow Supabase OAuth setup guides
2. Add redirect URLs in OAuth provider settings
3. Test on real device (not emulator) for best results

---

## ✅ Verification Checklist

Before considering setup complete, verify:

- [ ] `.env` file has correct Supabase credentials
- [ ] `supabase_setup.sql` ran successfully in SQL Editor
- [ ] `profiles` table exists in database
- [ ] Email auth is enabled in Supabase
- [ ] App runs without errors (`flutter run`)
- [ ] Can create new account
- [ ] New user appears in **Authentication** → **Users**
- [ ] New profile appears in **Table Editor** → `profiles` with role='renter'
- [ ] Can login with created account
- [ ] Home screen appears after login

---

## 🔒 Security Features

✅ **Row Level Security (RLS)** enabled
✅ Users can only see/edit their own profile
✅ Passwords hashed by Supabase
✅ JWT tokens for authentication
✅ Secure environment variables
✅ SQL injection protection

---

## 📧 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all checklist items
3. Check Supabase logs: **Logs** → **Auth Logs**
4. Review database logs: **Logs** → **Postgres Logs**

---

## 🎉 Success!

If you've completed all steps, your parking app now has:
- ✅ Working email authentication
- ✅ Automatic user profile creation
- ✅ All users assigned 'renter' role
- ✅ Secure database with RLS
- ✅ Clean, maintainable code structure
- ✅ OAuth support (if configured)

**Next steps:**
- Build out the home screen features
- Add parking spot functionality
- Implement host features (if needed)
- Add user profile editing

Happy coding! 🚀
