# Fix: Google Places API REQUEST_DENIED Error

## Problem
The API is returning `REQUEST_DENIED` because the API key is not authorized for your application.

## Solution

### Option 1: Remove API Key Restrictions (Quick Test - Development Only)

1. Go to [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)
2. Click on your API key (the one used in the app: `AIzaSyD5ZG8yheuA88UsmYT0fs2Xst5-75tyqKQ`)
3. Under **Application restrictions**, select **None**
4. Click **Save**
5. Test the app again

⚠️ **Warning**: This makes your API key unrestricted and vulnerable. Only use this for testing!

---

### Option 2: Properly Configure Android App Restrictions (Recommended)

#### Step 1: Get Your App's Package Name and SHA-1 Certificate

1. **Get Package Name**: Open `android/app/build.gradle` and find:
   ```gradle
   defaultConfig {
       applicationId "com.yourcompany.parking" // This is your package name
   }
   ```

2. **Get SHA-1 Certificate Fingerprint**:

   **For Debug Certificate** (Development):
   ```bash
   cd android
   ./gradlew signingReport
   ```

   Or on Windows:
   ```bash
   cd android
   gradlew.bat signingReport
   ```

   Look for the **SHA1** under `Variant: debug` - it will look like:
   ```
   SHA1: A1:B2:C3:D4:E5:F6:...
   ```

#### Step 2: Configure API Key Restrictions

1. Go to [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)
2. Click on your API key
3. Under **Application restrictions**:
   - Select **Android apps**
   - Click **Add an item**
   - Enter your **Package name** (from Step 1)
   - Enter your **SHA-1 certificate fingerprint** (from Step 1)
   - Click **Done**
4. Under **API restrictions**:
   - Select **Restrict key**
   - Check these APIs:
     - ✅ Places API (New)
     - ✅ Places API
     - ✅ Geocoding API
5. Click **Save**

#### Step 3: Wait and Test

- API key changes can take **5-10 minutes** to propagate
- Restart your app
- Test the search functionality

---

### Option 3: Create a New Unrestricted API Key (Quick Fix)

1. Go to [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)
2. Click **Create Credentials** > **API key**
3. Copy the new API key
4. Update `lib/core/config.dart`:
   ```dart
   static const String googleMapsApiKey = String.fromEnvironment(
     'GOOGLE_MAPS_API_KEY',
     defaultValue: 'YOUR_NEW_API_KEY_HERE',
   );
   ```
5. Keep it **unrestricted** for now (set restrictions later)
6. Test the app

---

## How to Get Your Package Name

**Option A**: Check `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.example.parking"  // <-- This is your package name
    }
}
```

**Option B**: Run this command:
```bash
flutter pub get
grep -r "package=" android/app/src/main/AndroidManifest.xml
```

---

## How to Get SHA-1 Fingerprint

### Method 1: Using Gradle (Recommended)
```bash
cd android
./gradlew signingReport
```

### Method 2: Using keytool (Manual)
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Method 3: In VS Code Terminal
```bash
cd android
.\gradlew signingReport  # Windows
./gradlew signingReport  # Mac/Linux
```

---

## Current API Key Configuration

Your current API key: `AIzaSyD5ZG8yheuA88UsmYT0fs2Xst5-75tyqKQ`

**From the screenshots, I can see**:
- API Key has restrictions enabled (shown in the credentials list)
- It's restricted to "Android apps, 3 APIs"

**This means**: The API key is configured for specific Android apps, but your current app's package name and SHA-1 are likely not added to the allowed list.

---

## Quick Test Steps

1. **First, try Option 1** (remove restrictions temporarily)
2. **Test if search works**
3. **If it works**, then the issue is with restrictions - use Option 2
4. **If it still doesn't work**, check that billing is enabled in Google Cloud

---

## Enable Billing (If Not Already Enabled)

⚠️ **Important**: Places API requires billing to be enabled, even for free tier usage.

1. Go to [Google Cloud Console - Billing](https://console.cloud.google.com/billing)
2. Link a billing account to your project
3. You still get **$200 free credit per month** for Google Maps Platform
4. Places API Autocomplete: **Free for first 1000 requests/month**, then $2.83 per 1000 requests

---

## Verification

After making changes, test with these steps:

1. **Stop and restart** the Flutter app completely
2. Open the Search screen
3. Type "kora" in the search bar
4. Watch the debug console:
   - ✅ Success: `Response status: 200`, `Found X suggestions`
   - ❌ Still failing: `API Error: REQUEST_DENIED`

---

## My Recommendation

**For immediate testing**: Use **Option 1** (remove restrictions)

**For production**: Use **Option 2** (proper Android restrictions with package name + SHA-1)

This is the safest and most secure approach once you've verified it works.
