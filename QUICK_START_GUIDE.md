# QuickPark - Quick Start Guide for Play Store Submission

## 🚀 Get Your App Published in 10 Steps

**Estimated time: 6-7 hours**

---

## Step 1: Generate Release Keystore (30 min)
**CRITICAL - Don't skip this!**

```bash
cd c:\Users\msi\Desktop\project\parking\android
keytool -genkey -v -keystore quickpark-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quickpark-key
```

**Then:**
1. Create file: `android/key.properties`
2. Add your passwords (see [KEYSTORE_GENERATION_GUIDE.md](KEYSTORE_GENERATION_GUIDE.md))
3. **BACKUP keystore to 2+ locations!**

**Why:** Without this, you can't publish OR update your app ever!

---

## Step 2: Get SHA-1 Fingerprint (5 min)

```bash
cd android
keytool -list -v -keystore quickpark-release-key.jks -alias quickpark-key
```

**Copy the SHA1 line** - you'll need it for Google Maps and OAuth.

---

## Step 3: Secure Google Maps API (20 min)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. **APIs & Services > Credentials**
4. Find API key: `AIzaSyBHQio6c2Lxi8WE62qqPiksOI8bciKDk2k`
5. Click **Edit**
6. **Application restrictions > Android apps**
7. Add:
   - Package: `com.sasri.parking.user`
   - SHA-1: (from Step 2)
8. **API restrictions > Restrict key**
9. Enable: Maps SDK, Places API, Geocoding API
10. **Save**

**Result:** API key only works with your signed app!

---

## Step 4: Switch Razorpay to Production (15 min)

1. Log in to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Go to **Settings > API Keys**
3. Generate production keys (if not done)
4. Copy **Key ID** and **Key Secret**
5. Open `.env` file
6. Update:
   ```env
   RAZORPAY_TEST_KEY=rzp_live_YOUR_KEY_HERE
   RAZORPAY_TEST_SECRET=YOUR_SECRET_HERE
   RAZORPAY_ENVIRONMENT=live
   ```
7. **Save** (do NOT commit to Git!)

---

## Step 5: Update Google OAuth (10 min)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. **APIs & Services > Credentials**
3. Find **OAuth 2.0 Client ID** (Android)
4. Add:
   - Package: `com.sasri.parking.user`
   - SHA-1: (from Step 2)
5. **Save**

**Result:** Google Sign-In will work in production!

---

## Step 6: Host Privacy Policy & Terms (30 min)

**Easy option: GitHub Pages**

1. Create new GitHub repository (e.g., "quickpark-legal")
2. Upload:
   - `privacy_policy.html`
   - `terms_of_service.html`
3. Go to **Settings > Pages**
4. Enable Pages with branch: main
5. Get URLs:
   - `https://yourusername.github.io/quickpark-legal/privacy_policy.html`
   - `https://yourusername.github.io/quickpark-legal/terms_of_service.html`

**Before uploading:** Update placeholders in both files!
- Search for `TO BE ADDED`
- Replace with your company info

**Save these URLs - you'll need them for Play Console!**

---

## Step 7: Test Release Build (1 hour)

```bash
cd c:\Users\msi\Desktop\project\parking
flutter clean
flutter build apk --release
flutter install --release
```

**Test checklist:**
- [ ] App launches without crashes
- [ ] Google Sign-In works
- [ ] Map displays correctly
- [ ] Search for parking works
- [ ] Make a real booking with SMALL payment amount
- [ ] QR code scanner works
- [ ] Refund the test payment immediately

**If anything fails, debug before continuing!**

---

## Step 8: Capture Screenshots (1 hour)

**You need 8 screenshots at 1080x1920 px**

**How to capture:**
1. Run app on emulator (Pixel device, 1080x1920 resolution)
2. Or use physical device and crop to 9:16 ratio

**Screens to capture:**
1. Home screen with parking list
2. Map view
3. Parking details
4. Booking confirmation
5. QR scanner
6. My Bookings
7. Payment screen (blur real card numbers!)
8. Profile screen

**Tips:**
- Use clean demo data
- Make sure app looks good
- Remove any test/debug info
- Export as PNG

**Save to:** `screenshots/` folder

---

## Step 9: Prepare Graphics (45 min)

### App Icon (512x512 PNG)
1. Check `assets/images/logo.png`
2. If not 512x512, resize or recreate
3. Export as 32-bit PNG
4. No transparency, no rounded corners
5. Save as `app_icon_512.png`

### Feature Graphic (1024x500 PNG)
Create a banner with:
- QuickPark logo
- Text: "Find, Book, Park"
- White background, black elements (brand colors)
- Save as `feature_graphic.png`

**Tools:** Canva (free), Figma, Photoshop, or GIMP

---

## Step 10: Build Final AAB & Submit (1 hour)

### Build AAB:
```bash
flutter build appbundle --release
```

**Output:** `build\app\outputs\bundle\release\app-release.aab`

### Submit to Play Console:

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Enter app details:
   - Name: **QuickPark**
   - Default language: English (or your language)
   - App type: **App**
   - Free or paid: **Free**

4. **Store Listing:**
   - Upload `app_icon_512.png`
   - Upload `feature_graphic.png`
   - Upload 8 screenshots
   - **App name:** QuickPark - Find & Book Parking
   - **Short description:** (copy from [PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md))
   - **Full description:** (copy from [PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md))
   - **Email:** support@quickpark.app (or your email)
   - **Privacy policy URL:** (from Step 6)
   - **Category:** Maps & Navigation

5. **Content Rating:**
   - Complete questionnaire
   - Answer honestly
   - Submit for rating

6. **Pricing & Distribution:**
   - Countries: Select all or specific regions
   - Confirm policies

7. **App Content:**
   - Complete all required sections
   - Data safety form (describe data collection)

8. **Release:**
   - **Production > Create new release**
   - Upload `app-release.aab`
   - **Release name:** 1.0.0
   - **Release notes:** (copy from [PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md))
   - **Save > Review > Start rollout to Production**

9. **Wait for Review**
   - Typically 1-7 days
   - Monitor email for updates

---

## ✅ Pre-Submission Checklist

Before clicking "Submit":

- [ ] Keystore generated and backed up
- [ ] key.properties file created
- [ ] Google Maps API restricted
- [ ] Razorpay using live keys
- [ ] Google OAuth updated with release SHA-1
- [ ] Privacy policy hosted on public URL
- [ ] Terms hosted on public URL (optional)
- [ ] Legal docs updated (no "TO BE ADDED" placeholders)
- [ ] Release build tested successfully
- [ ] Real payment tested and refunded
- [ ] 8 screenshots captured (1080x1920)
- [ ] App icon created (512x512)
- [ ] Feature graphic created (1024x500)
- [ ] AAB file built
- [ ] All Play Console sections completed
- [ ] No crashes or errors in release build

---

## 🆘 Common Issues & Fixes

### "Keystore not found"
- Check `android/key.properties` exists
- Verify `storeFile=../quickpark-release-key.jks` (correct path)
- Keystore should be in `android/` folder

### "Google Sign-In not working"
- Verify SHA-1 in Google Cloud Console
- Ensure using release build (not debug)
- Check package name matches: `com.sasri.parking.user`

### "Maps not loading"
- Verify API key restrictions
- Check API key is enabled for Maps SDK for Android
- Ensure internet permission in manifest

### "Payment fails"
- Verify using live Razorpay keys
- Check `RAZORPAY_ENVIRONMENT=live`
- Test with real payment method

### "Build fails"
- Run `flutter clean`
- Delete `build` folder
- Run `flutter pub get`
- Try again

---

## 📊 After Submission

### Review Process:
- **Time:** Usually 1-7 days
- **Monitor:** Email and Play Console
- **Be ready:** To respond to any issues

### If Rejected:
- Read rejection reason carefully
- Fix the issue
- Resubmit

### After Approval:
- Test download from Play Store
- Share with friends/beta testers
- Monitor reviews and ratings
- Respond to user feedback
- Fix bugs in updates

---

## 📚 Full Documentation

For detailed information, see:
- **Master Checklist:** [PLAY_STORE_CHECKLIST.md](PLAY_STORE_CHECKLIST.md)
- **Keystore Guide:** [KEYSTORE_GENERATION_GUIDE.md](KEYSTORE_GENERATION_GUIDE.md)
- **API Security:** [API_SECURITY_GUIDE.md](API_SECURITY_GUIDE.md)
- **Store Listing:** [PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md)
- **Implementation Summary:** [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)

---

## 💪 You've Got This!

Follow these 10 steps carefully, and your app will be on the Play Store soon!

**Most important:**
1. Don't lose your keystore
2. Test thoroughly before submitting
3. Use production API keys
4. Provide accurate store listing

**Good luck! 🚀**

---

*QuickPark v1.0.0 - Play Store Submission Guide*
