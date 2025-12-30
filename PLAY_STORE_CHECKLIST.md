# Play Store Submission Checklist for Parking App

## Status: Pre-Submission Preparation
Last Updated: 2025-12-30

---

## 1. App Identity & Branding

### 1.1 Package Name
- [ ] **CRITICAL**: Change package name from `com.sasri.parking.user` to your own unique package name
  - File: `android/app/build.gradle.kts`
  - File: `AndroidManifest.xml`
  - Must be unique and match your Google Play Console setup
  - Format: `com.yourcompany.parkingapp` or similar

### 1.2 App Name
- [ ] Update app name from "parking" to proper branding
  - File: `AndroidManifest.xml` (android:label)
  - File: `pubspec.yaml` (name field)
  - Should be user-friendly and descriptive

### 1.3 App Icon
- [x] Logo exists: `assets/images/logo.png`
- [ ] Create adaptive icon (foreground + background) for Android
- [ ] Test icon on different Android versions (8.0+)
- [ ] Ensure icon meets Play Store guidelines (512x512 PNG for store)

---

## 2. Security & Credentials

### 2.1 Release Signing Configuration
- [ ] **CRITICAL**: Generate release keystore (.jks file)
  ```bash
  keytool -genkey -v -keystore parking-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias parking-key
  ```
- [ ] Create `android/key.properties` file (DO NOT commit to Git)
  ```properties
  storePassword=YOUR_KEYSTORE_PASSWORD
  keyPassword=YOUR_KEY_PASSWORD
  keyAlias=parking-key
  storeFile=../parking-release-key.jks
  ```
- [ ] Update `android/app/build.gradle.kts` to use release signing config
- [ ] Add `key.properties` and `*.jks` to `.gitignore`
- [ ] **BACKUP KEYSTORE FILE SAFELY** - losing it means you can never update your app!

### 2.2 API Keys & Credentials Security
- [ ] **CRITICAL**: Remove hardcoded Google Maps API key from `AndroidManifest.xml`
  - Current: `AIzaSyBHQio6c2Lxi8WE62qqPiksOI8bciKDk2k`
  - Use Android-specific API key with restrictions
  - Restrict to your app's SHA-1 fingerprint and package name

- [ ] **CRITICAL**: Switch Razorpay to production keys
  - Current in `.env`: Test keys (`rzp_test_*`)
  - Get production keys from Razorpay dashboard
  - Update `RAZORPAY_ENVIRONMENT=live`

- [ ] Verify Supabase credentials are production-ready
  - Current URL: `https://eivjgwxyijhfmnyrcbcb.supabase.co`
  - Ensure this is your production instance
  - Review Row Level Security (RLS) policies

- [ ] **CRITICAL**: DO NOT commit `.env` file to Git
  - Add `.env` to `.gitignore`
  - Document required environment variables separately

### 2.3 OAuth Configuration
- [ ] Configure Google Sign-In for release
  - Get SHA-1 fingerprint from release keystore
  - Add to Google Cloud Console OAuth 2.0 credentials

- [ ] Configure Apple Sign-In
  - Verify Apple Developer account settings
  - Test Sign in with Apple flow

- [ ] Update Supabase OAuth redirect URLs
  - Current: `io.supabase.auth://login`
  - Ensure matches your package name if changed

---

## 3. Legal & Compliance

### 3.1 Privacy Policy (REQUIRED)
- [ ] **CRITICAL**: Create Privacy Policy document
  - Must cover all data collection practices
  - Required data to document:
    - Location data (GPS, address)
    - Personal information (name, email, phone)
    - Payment information (Razorpay)
    - Camera access (QR scanning)
    - Device information
    - Supabase backend data storage
  - Host on accessible URL (website, GitHub pages, etc.)
  - Add link to Play Store listing

### 3.2 Terms of Service
- [ ] Create Terms of Service document
  - User responsibilities
  - Parking booking terms
  - Payment and refund policy
  - Liability disclaimers
  - Host vs Renter terms
  - Add link to Play Store listing

### 3.3 Data Safety Section
- [ ] Complete Data Safety form in Play Console
  - Location data collection: YES (precise location)
  - Personal info: YES (name, email, phone)
  - Financial info: YES (payment methods via Razorpay)
  - Photos/Videos: NO (unless you add this feature)
  - Device ID: Potentially YES (check Supabase analytics)
  - Data encryption: YES (in transit via HTTPS)
  - Data deletion: Document process for users

### 3.4 Permissions Justification
Prepare explanations for Play Store review:
- [ ] `ACCESS_FINE_LOCATION` - Find nearby parking spaces
- [ ] `ACCESS_COARSE_LOCATION` - General location for parking search
- [ ] `ACCESS_BACKGROUND_LOCATION` - Navigate to parking spot during active booking
- [ ] `CAMERA` - Scan QR codes to verify parking
- [ ] `POST_NOTIFICATIONS` - Booking confirmations and updates
- [ ] `READ/WRITE_EXTERNAL_STORAGE` - Cache parking images (may not be needed on Android 10+)

---

## 4. App Configuration

### 4.1 Version Management
- [ ] Set initial version for release
  - File: `android/app/build.gradle.kts`
  - Current: `versionCode = 1`, `versionName = "1.0.0"`
  - Recommended first release: `versionCode = 1`, `versionName = "1.0.0"`
  - Document versioning strategy for future updates

### 4.2 Build Configuration
- [ ] Update `android/app/build.gradle.kts`:
  - [ ] Set `minSdkVersion` explicitly (recommended: 21 or higher)
  - [ ] Set `targetSdkVersion` to latest (34 for Android 14 as of 2024)
  - [ ] Set `compileSdkVersion` to latest (34)
  - [ ] Enable ProGuard/R8 for release builds
  - [ ] Enable code shrinking and obfuscation

### 4.3 Permissions Optimization
- [ ] Review `AndroidManifest.xml` permissions
  - [ ] Remove `WRITE_EXTERNAL_STORAGE` if not needed (Android 10+)
  - [ ] Add `maxSdkVersion` for legacy permissions
  - [ ] Ensure all permissions have runtime request handling

### 4.4 Deep Links & App Links
- [ ] Verify Supabase auth deep links work
  - Current scheme: `io.supabase.auth://login`
  - Test OAuth flows (Google, Apple)
- [ ] Consider adding Android App Links for web integration

---

## 5. Content & Marketing Assets

### 5.1 Play Store Listing Content
- [ ] **App Title** (max 50 characters)
  - Should be descriptive and include keywords
  - Example: "Parking Finder - Book Parking Spots"

- [ ] **Short Description** (max 80 characters)
  - Hook users quickly
  - Example: "Find, book and pay for parking spaces instantly with QR check-in"

- [ ] **Full Description** (max 4000 characters)
  - Highlight key features:
    - Find nearby parking spaces with live availability
    - Book in advance or on-demand
    - Secure payments via Razorpay
    - QR code check-in verification
    - Google Maps integration
    - Real-time booking management
    - Save multiple vehicles
    - Booking history and notifications
  - Include benefits for users
  - Add call-to-action
  - Mention safety and security features

### 5.2 Screenshots (REQUIRED)
- [ ] **Minimum 2, recommended 8 screenshots**
  - Phone screenshots: 16:9 or 9:16 ratio, 1080x1920px minimum
  - Required screens to capture:
    1. Home screen showing parking listings
    2. Map view with nearby parking
    3. Parking details page
    4. Booking confirmation
    5. QR scanner interface
    6. Profile/My Bookings
    7. Search with filters
    8. Payment screen (mock data)
  - Add descriptive captions for each screenshot
  - Consider adding promotional text overlay

### 5.3 Feature Graphic (REQUIRED)
- [ ] Create feature graphic (1024x500 PNG)
  - Will be shown in Play Store search and featured sections
  - Should showcase app logo and main value proposition
  - No border or padding needed

### 5.4 Promotional Assets (Optional but Recommended)
- [ ] Promotional graphic (180x120 PNG) - for older devices
- [ ] Promotional video (YouTube URL)
  - You have: `assets/images/car.mp4` - consider uploading to YouTube
  - Max 30 seconds recommended
  - Showcase key features and user flow

### 5.5 App Category & Tags
- [ ] Select primary category: "Maps & Navigation" or "Travel & Local"
- [ ] Add relevant tags: parking, navigation, booking, city parking, etc.
- [ ] Set content rating (complete questionnaire)

---

## 6. Testing & Quality Assurance

### 6.1 Pre-Release Testing
- [ ] Test on multiple Android devices/emulators
  - [ ] Android 7.0 (API 24) - minimum recommended
  - [ ] Android 10 (API 29) - scoped storage
  - [ ] Android 12 (API 31) - privacy dashboard
  - [ ] Android 13 (API 33) - notification permission
  - [ ] Android 14 (API 34) - latest

- [ ] Test all user flows:
  - [ ] Sign up (email)
  - [ ] Sign in (Google, Apple)
  - [ ] Search for parking
  - [ ] View parking details
  - [ ] Make a booking
  - [ ] Payment flow (test mode initially)
  - [ ] QR code scanning
  - [ ] View booking history
  - [ ] Manage vehicles
  - [ ] Update profile
  - [ ] Notifications

- [ ] Test permissions flows:
  - [ ] Location permission (foreground)
  - [ ] Location permission (background) - must be explained
  - [ ] Camera permission (QR scanner)
  - [ ] Notification permission (Android 13+)

### 6.2 Build Release APK/AAB
- [ ] Build App Bundle (AAB) - recommended
  ```bash
  flutter build appbundle --release
  ```
  - Output: `build/app/outputs/bundle/release/app-release.aab`

- [ ] Alternatively, build APK
  ```bash
  flutter build apk --release
  ```

- [ ] Test the release build on real device
  ```bash
  flutter install --release
  ```

### 6.3 Performance & Size
- [ ] Check app size (should be under 150MB uncompressed)
- [ ] Test app startup time
- [ ] Test on low-end devices
- [ ] Monitor memory usage
- [ ] Test offline behavior (graceful degradation)

### 6.4 Security Testing
- [ ] No sensitive data in logs
- [ ] HTTPS for all API calls (Supabase uses HTTPS)
- [ ] Validate payment flows are secure
- [ ] Test RLS policies in Supabase
- [ ] Ensure no hardcoded credentials in source

---

## 7. Google Play Console Setup

### 7.1 Create App Listing
- [ ] Sign in to Google Play Console
- [ ] Create new application
- [ ] Select default language
- [ ] Enter app title

### 7.2 Store Listing
- [ ] Upload app icon (512x512 PNG)
- [ ] Upload feature graphic
- [ ] Upload screenshots
- [ ] Enter app description
- [ ] Add privacy policy URL
- [ ] Add terms of service URL (optional but recommended)
- [ ] Set app category
- [ ] Enter contact email
- [ ] Add website URL (optional)

### 7.3 Content Rating
- [ ] Complete content rating questionnaire
  - Answer questions honestly about app content
  - Parking app should get Everyone or PEGI 3 rating
  - Submit for rating

### 7.4 Pricing & Distribution
- [ ] Set app as Free or Paid
- [ ] Select countries for distribution
- [ ] Opt in/out of Google Play for Education
- [ ] Opt in/out of Android Wear, Android TV, Chromebook
- [ ] Review program policies

### 7.5 App Releases
- [ ] Create release in Production track (or Internal/Closed/Open testing first)
- [ ] Upload AAB file
- [ ] Add release notes
- [ ] Review and roll out

### 7.6 Additional Settings
- [ ] Set up merchant account if using in-app purchases (Razorpay is external, may not apply)
- [ ] Configure ads (if applicable)
- [ ] Set up Firebase (optional for analytics)
- [ ] Configure app signing (Google Play App Signing recommended)

---

## 8. Post-Submission

### 8.1 Review Process
- [ ] App submitted for review
- [ ] Monitor Play Console for review status
- [ ] Respond to any policy violations or issues
- [ ] Average review time: 1-7 days

### 8.2 After Approval
- [ ] Test app download from Play Store
- [ ] Monitor crash reports in Play Console
- [ ] Monitor user reviews and ratings
- [ ] Set up alerts for crashes and ANRs
- [ ] Plan for regular updates

### 8.3 Monitoring & Analytics
- [ ] Set up Firebase Analytics (optional)
- [ ] Monitor Supabase usage and costs
- [ ] Monitor Razorpay transactions
- [ ] Track user engagement metrics
- [ ] Monitor Google Maps API usage and billing

---

## 9. Common Rejection Reasons (Avoid These!)

- [ ] **Ensure compliance:**
  - [ ] Missing privacy policy
  - [ ] Insufficient permission justification (especially background location)
  - [ ] Hardcoded test credentials visible
  - [ ] App crashes on startup
  - [ ] Broken OAuth flows
  - [ ] Unsafe payment handling
  - [ ] Misleading app title or description
  - [ ] Poor screenshot quality
  - [ ] Icon doesn't meet guidelines
  - [ ] Missing or incomplete Data Safety section
  - [ ] Using deprecated or removed APIs
  - [ ] Not targeting recent Android SDK version
  - [ ] Requesting unnecessary permissions

---

## 10. Pre-Flight Final Checklist

**Before uploading to Play Console:**

- [ ] Package name is unique and correct
- [ ] Keystore is created and backed up securely
- [ ] All API keys are production-ready and secured
- [ ] Privacy Policy URL is live and accessible
- [ ] App name is finalized
- [ ] Version code and name are set
- [ ] Release build installs and runs successfully
- [ ] All features tested on release build
- [ ] No hardcoded test data visible to users
- [ ] All screenshots and graphics are ready
- [ ] App description is compelling and complete
- [ ] No crash on startup
- [ ] OAuth flows work correctly
- [ ] Payment flow tested (test mode is acceptable initially)
- [ ] Location services work properly
- [ ] QR scanning works
- [ ] All permissions are justified and requested at appropriate times

---

## Additional Resources

- [Google Play Console](https://play.google.com/console)
- [Android App Bundle Guide](https://developer.android.com/guide/app-bundle)
- [Play Console Help Center](https://support.google.com/googleplay/android-developer)
- [App Signing](https://developer.android.com/studio/publish/app-signing)
- [Privacy Policy Generator](https://app-privacy-policy-generator.firebaseapp.com/)

---

## Notes

- Current app version: 1.0.0 (Build 1)
- Current package: com.sasri.parking.user ⚠️ MUST CHANGE
- Flutter SDK: Compatible with current setup
- Min SDK: To be set explicitly (recommended 21+)
- Target SDK: Should be 33 or 34

**CRITICAL FIRST STEPS:**
1. Change package name
2. Generate keystore
3. Create privacy policy
4. Secure API keys
5. Build and test release version
