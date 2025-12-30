# API Security Guide for QuickPark

## CRITICAL: Secure Your API Keys Before Publishing!

This guide will help you properly secure all API keys and credentials in your QuickPark app.

---

## 1. Google Maps API Key

### Current Status: ⚠️ HARDCODED IN AndroidManifest.xml
**Location:** `android/app/src/main/AndroidManifest.xml:68`
**Current Key:** `AIzaSyBHQio6c2Lxi8WE62qqPiksOI8bciKDk2k`

### Issues:
- Visible in source code
- No restrictions applied
- Can be extracted from APK

### Action Required:

#### Step 1: Create a Production API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create a new one)
3. Go to **APIs & Services > Credentials**
4. Click **Create Credentials > API Key**
5. Name it: "QuickPark Android Production Key"

#### Step 2: Restrict the API Key
1. Click **Edit** on your new API key
2. Under **Application restrictions**:
   - Select **Android apps**
   - Click **Add an item**
   - Package name: `com.sasri.parking.user`
   - SHA-1 fingerprint: Get from your release keystore (see below)
3. Under **API restrictions**:
   - Select **Restrict key**
   - Enable only these APIs:
     - Maps SDK for Android
     - Places API
     - Geolocation API
     - Geocoding API
4. Click **Save**

#### Step 3: Get SHA-1 Fingerprint from Release Keystore
```bash
cd android
keytool -list -v -keystore quickpark-release-key.jks -alias quickpark-key
```
Copy the SHA1 fingerprint (format: `AA:BB:CC:DD:...`)

#### Step 4: Update AndroidManifest.xml
The API key is already in the manifest. You can either:
- **Option A (Recommended):** Replace with your new restricted production key
- **Option B:** Keep the key in manifest but ensure it's properly restricted

**IMPORTANT:** Once you add SHA-1 restrictions, the key will ONLY work with your signed APK!

#### Step 5: Create a Debug API Key (Optional)
For development, create a separate unrestricted key or one restricted to your debug keystore SHA-1:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## 2. Razorpay API Keys

### Current Status: ⚠️ TEST KEYS IN .ENV FILE
**Location:** `.env`
**Current Keys:**
- Test Key: `rzp_test_RvNP7q1DMTG2fT`
- Test Secret: `Eof7W6tuZmf65nVz623Cipzp`
- Environment: `test`

### Action Required:

#### Step 1: Get Production Keys
1. Log in to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Go to **Settings > API Keys**
3. Click **Generate Key** (if not already generated)
4. Copy **Key ID** (starts with `rzp_live_`)
5. Copy **Key Secret** (keep this VERY secure!)

#### Step 2: Update .env File
**CRITICAL:** Only update `.env` locally, NEVER commit it to Git!

Update these lines in `.env`:
```env
RAZORPAY_TEST_KEY=rzp_live_YOUR_LIVE_KEY_HERE
RAZORPAY_TEST_SECRET=YOUR_LIVE_SECRET_HERE
RAZORPAY_ENVIRONMENT=live
```

**Note:** The variable names say "TEST" but you should use your LIVE keys for production.

#### Step 3: Enable Webhooks (Optional but Recommended)
1. In Razorpay Dashboard, go to **Settings > Webhooks**
2. Add webhook URL: `https://eivjgwxyijhfmnyrcbcb.supabase.co/functions/v1/razorpay-webhook` (update with your actual endpoint)
3. Select events: `payment.captured`, `payment.failed`, `refund.created`
4. Copy the webhook secret
5. Store it securely (you may need it for backend verification)

#### Step 4: Test Payment Flow
Before going live:
1. Use test mode first
2. Complete a test transaction
3. Verify booking confirmation works
4. Then switch to live keys
5. Test with a small real transaction (you can refund it)

---

## 3. Supabase Credentials

### Current Status: ✓ IN .ENV FILE (Good!)
**Location:** `.env`
**URL:** `https://eivjgwxyijhfmnyrcbcb.supabase.co`
**Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### Verification Required:

#### Step 1: Verify Production Instance
1. Log in to [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Go to **Settings > API**
4. Verify the URL and anon key match your `.env` file
5. Check that this is your PRODUCTION instance (not a dev/test project)

#### Step 2: Review Row Level Security (RLS)
This is CRITICAL for data security!

1. In Supabase Dashboard, go to **Authentication > Policies**
2. Verify RLS is enabled for these tables:
   - ✓ profiles
   - ✓ bookings
   - ✓ parking_spaces
   - ✓ vehicles
   - ✓ reviews

3. Check that policies are correctly configured:
   - Users can only read their own profile
   - Users can only see their own bookings
   - Parking spaces are publicly readable but only hosts can edit
   - Vehicle data is private to each user

#### Step 3: Verify OAuth Settings
1. Go to **Authentication > URL Configuration**
2. Verify redirect URLs include:
   - `io.supabase.auth://login` (for mobile OAuth)
3. Go to **Authentication > Providers**
4. Verify Google and Apple Sign-In are properly configured

#### Step 4: Check Database Indexes
For better performance:
1. Go to **Database > Indexes**
2. Ensure indexes exist on:
   - `parking_spaces.latitude` and `parking_spaces.longitude` (for location queries)
   - `bookings.user_id` (for user booking lookups)
   - `bookings.parking_space_id` (for parking space bookings)

---

## 4. OAuth Configuration (Google & Apple)

### Google Sign-In

#### Step 1: Update OAuth Client
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. **APIs & Services > Credentials**
3. Find your **OAuth 2.0 Client ID** for Android
4. Verify/Add:
   - Package name: `com.sasri.parking.user`
   - SHA-1 from release keystore (get from keystore as shown in section 1)

#### Step 2: Test OAuth Flow
1. Build release APK
2. Install on device
3. Try "Sign in with Google"
4. Verify it works with production signing

### Apple Sign-In

#### Step 1: Verify Configuration
1. Check that Sign in with Apple is configured in Supabase
2. Verify Apple Developer account settings
3. Test the flow on a device

---

## 5. Security Checklist Before Publishing

### Critical Items:
- [ ] Google Maps API key is restricted to your package name + SHA-1
- [ ] Razorpay keys switched from test to live
- [ ] Razorpay environment changed to "live"
- [ ] Supabase is production instance
- [ ] Supabase RLS policies are enabled and tested
- [ ] Google OAuth configured with release SHA-1
- [ ] Apple Sign-In tested and working
- [ ] `.env` file is in `.gitignore` (already done ✓)
- [ ] No API keys in Git history

### Additional Security:
- [ ] Test all authentication flows with release build
- [ ] Verify location permissions work correctly
- [ ] Test QR code scanning
- [ ] Verify payment flow end-to-end
- [ ] Check that unauthorized users cannot access other users' data
- [ ] Test booking flow with real payment (small amount, then refund)

---

## 6. Environment Variable Management

### Current Setup:
The app uses `flutter_dotenv` to load environment variables from `.env` file.

### Best Practices:
1. **Never commit `.env` to Git** (already in .gitignore ✓)
2. **Create `.env.example` for documentation:**

Create `c:\Users\msi\Desktop\project\parking\.env.example`:
```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Razorpay Configuration
RAZORPAY_TEST_KEY=rzp_live_your_live_key
RAZORPAY_TEST_SECRET=your_razorpay_secret
RAZORPAY_ENVIRONMENT=live

# App Configuration
APP_NAME=QuickPark
APP_VERSION=1.0.0
```

3. **Document required variables** in README
4. **Use separate .env files** for dev/staging/production if needed

---

## 7. Testing Secure Build

### Test Release Build with Production Keys:

```bash
# 1. Ensure .env has production keys
# 2. Build release APK
flutter clean
flutter build apk --release

# 3. Install on device
flutter install --release

# 4. Test these flows:
# - Sign in with Google
# - Sign in with Apple
# - Search for parking (tests location + maps)
# - Make a booking (tests payment)
# - Scan QR code (tests camera)
```

### What to Verify:
- [ ] Google Sign-In works
- [ ] Apple Sign-In works (if applicable)
- [ ] Map displays correctly
- [ ] Location search works
- [ ] Payment processes successfully (use small amount, refund after)
- [ ] QR code scanning works
- [ ] Booking confirmation received
- [ ] No errors in logs

---

## 8. API Usage Monitoring

### Set Up Monitoring:

#### Google Maps API:
1. [Google Cloud Console](https://console.cloud.google.com/)
2. **APIs & Services > Dashboard**
3. Monitor daily usage
4. Set up billing alerts
5. Current free tier: $200/month credit

#### Razorpay:
1. [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Monitor transactions
3. Check for failed payments
4. Review settlement reports

#### Supabase:
1. [Supabase Dashboard](https://app.supabase.com/)
2. **Settings > Usage**
3. Monitor:
   - Database size
   - Bandwidth
   - Storage
   - Authentication users
4. Set up usage alerts

---

## 9. Quick Reference: Where Keys Are Used

| Service | Key Location | File |
|---------|-------------|------|
| Google Maps | AndroidManifest.xml | `android/app/src/main/AndroidManifest.xml:68` |
| Supabase | .env file | `.env` (loaded in `lib/core/supabase_config.dart`) |
| Razorpay | .env file | `.env` (loaded in `lib/core/config.dart`) |
| OAuth Redirect | build.gradle.kts | `android/app/build.gradle.kts:30` |

---

## 10. Emergency: If Keys Are Compromised

If you accidentally commit API keys to Git:

### Immediate Actions:
1. **Rotate all compromised keys immediately**
2. **Revoke old keys in respective dashboards**
3. **Generate new keys**
4. **Update .env file locally**
5. **Remove from Git history:**
```bash
# Use BFG Repo Cleaner or git filter-branch
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all
```
6. **Force push** (if already pushed)
7. **Notify your team**

### Prevention:
- Use Git hooks to prevent committing sensitive files
- Review changes before committing
- Use `.gitignore` properly (already set up ✓)

---

## Contact for Help

If you encounter issues with API configuration:

- **Google Maps:** [Google Cloud Support](https://cloud.google.com/support)
- **Razorpay:** [Razorpay Support](https://razorpay.com/support/)
- **Supabase:** [Supabase Support](https://supabase.com/support)

---

## Next Steps

After securing all APIs:
1. ✓ Generate keystore (see KEYSTORE_GENERATION_GUIDE.md)
2. ✓ Update AndroidManifest.xml with restricted Google Maps key
3. ✓ Switch Razorpay to live keys
4. ✓ Verify Supabase RLS policies
5. ✓ Test release build thoroughly
6. → Build release AAB
7. → Upload to Play Console
