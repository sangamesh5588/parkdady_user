# Google Play Privacy Policy Requirement

## Why Google Play Needs a Privacy Policy

Your app uses **sensitive permissions** that require a privacy policy:

1. **CAMERA** - For QR code scanning of parking tickets
2. **RECORD_AUDIO** - For voice search feature
3. **ACCESS_FINE_LOCATION** - For finding nearby parking spaces

Google Play **requires** apps using these permissions to have a **publicly accessible privacy policy**.

## What Changed in This Release

### ✅ Permissions Optimized (Version 1.0.1)

**REMOVED (Unnecessary):**
- ❌ ACCESS_BACKGROUND_LOCATION (not used in your app)
- ❌ READ_EXTERNAL_STORAGE (not needed with scoped storage)
- ❌ WRITE_EXTERNAL_STORAGE (not needed with scoped storage)

**KEPT (Required for core features):**
- ✅ INTERNET - API calls, Supabase, Razorpay
- ✅ ACCESS_NETWORK_STATE - Connectivity checks
- ✅ ACCESS_FINE_LOCATION - Find nearby parking (core feature)
- ✅ ACCESS_COARSE_LOCATION - Backup location provider
- ✅ CAMERA - QR code scanning for parking tickets
- ✅ RECORD_AUDIO - Voice search feature
- ✅ POST_NOTIFICATIONS - Booking notifications

## How to Add Privacy Policy to Google Play Console

### Option 1: Use Your Existing Privacy Policy (Recommended)

You already have a privacy policy at: **https://www.parkdady.com/privacy-policy**

1. Go to Google Play Console
2. Navigate to **Policy** → **App content**
3. Click on **Privacy Policy**
4. Enter the URL: `https://www.parkdady.com/privacy-policy`
5. Click **Save**

### Option 2: Update Your Privacy Policy

If your current privacy policy doesn't cover these permissions, you need to add sections about:

1. **Location Data Collection**
   - "We collect your location to show nearby parking spaces"
   - "Location data is only collected when you use the app"
   - "We don't track your location in the background"

2. **Camera Permission**
   - "We use your camera only for scanning QR codes of parking tickets"
   - "Camera access is requested only when you use the QR scanner"
   - "We don't store or transmit camera images"

3. **Microphone Permission**
   - "We use your microphone for voice search feature"
   - "Audio is processed on-device only"
   - "We don't store or transmit voice recordings"

### Option 3: Generate a New Privacy Policy

Use a privacy policy generator that covers:
- Data collection (location, payment info, user account)
- Third-party services (Google Maps, Razorpay, Supabase)
- Camera and microphone usage
- Data storage and security
- User rights (access, deletion, etc.)

**Free Privacy Policy Generators:**
- https://www.privacypolicygenerator.info/
- https://www.freeprivacypolicy.com/
- https://app-privacy-policy-generator.firebaseapp.com/

## Steps to Upload App to Google Play Console

### 1. Upload the New App Bundle

1. Go to Google Play Console
2. Navigate to **Release** → **Internal testing**
3. Click **Create new release**
4. Upload the file: `build\app\outputs\bundle\release\app-release.aab`
5. The file size is 55.1MB, version code 2, version name 1.0.1

### 2. Add Privacy Policy URL

1. Navigate to **Policy** → **App content**
2. Click on **Privacy Policy**
3. Add your privacy policy URL
4. Click **Save**

### 3. Fill Out Data Safety Section

You'll need to declare what data you collect:

**Location:**
- ✅ Approximate location (ACCESS_COARSE_LOCATION)
- ✅ Precise location (ACCESS_FINE_LOCATION)
- Purpose: "App functionality" (finding parking)
- Data is: Collected, Not shared with third parties, Ephemeral (not stored)

**Photos and videos:**
- ✅ Camera access (CAMERA)
- Purpose: "App functionality" (QR scanning)
- Data is: Not collected (only camera access, no storage)

**Audio:**
- ✅ Voice or sound recordings (RECORD_AUDIO)
- Purpose: "App functionality" (voice search)
- Data is: Not collected (processed on-device only)

**Personal info:**
- ✅ Name
- ✅ Email address
- ✅ Phone number
- Purpose: "Account management"
- Data is: Collected, Encrypted in transit, User can request deletion

**Financial info:**
- ✅ Payment info (Razorpay)
- Purpose: "Payments"
- Data is: Not collected by you (handled by Razorpay)

### 4. Complete App Content Questionnaire

Answer questions about:
- Ads: If you show ads
- Target audience: Age rating
- Content rating: ESRB, PEGI, etc.
- News apps: Not applicable
- COVID-19 apps: Not applicable
- Data safety: Covered above

### 5. Review and Publish

1. Review all the information
2. Click **Review release**
3. Click **Start rollout to Internal testing**
4. Wait for Google Play to process (usually 1-2 hours)

## Important Notes

### CAMERA Permission

Google flags CAMERA as a sensitive permission. You MUST:
1. ✅ Have a privacy policy explaining camera usage
2. ✅ Request permission at runtime (already handled by mobile_scanner)
3. ✅ Explain to users WHY you need camera access
4. ✅ Only use camera for stated purpose (QR scanning)

### Permission Best Practices

Your app now follows Google Play's best practices:
- Only requests permissions actually used
- Removed unnecessary permissions
- Clear purpose for each permission
- Runtime permission requests
- User-friendly permission explanations

## Common Play Console Errors & Solutions

### "Your app is using permissions that require a privacy policy"
**Solution:** Add privacy policy URL in Play Console (see Option 1 above)

### "Version code 1 has already been used"
**Solution:** Already fixed - new version code is 2

### "Your app currently targets API level 34"
**Solution:** Already fixed - now targets API level 35

### "Data safety section is incomplete"
**Solution:** Fill out Data Safety section as described above

## Testing Checklist

Before releasing to production:

- [ ] Privacy policy URL is added to Play Console
- [ ] Data safety section is complete
- [ ] App content questionnaire is filled
- [ ] Test QR scanner on physical device
- [ ] Test voice search feature
- [ ] Test location-based parking search
- [ ] Test payment flow with Razorpay
- [ ] Test all permission requests show proper explanations
- [ ] Verify internal testing release is approved
- [ ] Get feedback from internal testers

## Contact

If you have questions about privacy policy or Play Console setup:
1. Check Google Play Console Help: https://support.google.com/googleplay/android-developer
2. Review App Privacy Policy guidelines: https://support.google.com/googleplay/android-developer/answer/9859455

## Summary

✅ App is ready for upload to Google Play Console
✅ Permissions are optimized and minimal
✅ Version updated to 1.0.1 (versionCode 2)
✅ Target SDK is 35 (Android 15)
✅ App bundle built successfully (55.1MB)

**Next step:** Add privacy policy URL to Google Play Console and upload the app bundle!
