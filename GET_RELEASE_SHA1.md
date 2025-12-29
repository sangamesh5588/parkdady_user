# How to Get Release SHA-1 for Google Play Store

## Important: Debug vs Release Certificates

- **Debug certificate**: Used during development (what you have now)
- **Release certificate**: Used for Play Store uploads (what you need)

## Option 1: If You Have an Existing Keystore

If you already created a release keystore for signing your app:

```bash
keytool -list -v -keystore path/to/your/release-keystore.jks -alias your-key-alias
```

Replace:
- `path/to/your/release-keystore.jks` with your keystore path
- `your-key-alias` with your key alias

You'll be asked for the keystore password.

## Option 2: Create a New Release Keystore

If you haven't created one yet, create it now:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Follow the prompts to set:
- Password
- Name
- Organization
- City
- State
- Country

Then get the SHA-1:
```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

## Option 3: Get SHA-1 from Play Console (After Upload)

1. Upload your app to Play Console (internal testing track)
2. Go to **Release > Setup > App signing**
3. Copy the **App signing certificate SHA-1**
4. Add it to your Google Cloud API key restrictions

## Recommended Approach for Your Situation

Since you're testing with the debug build now, here's the best workflow:

### For Development (Now):
1. Keep API key **unrestricted** temporarily for testing
2. OR add your debug SHA-1 (which you already have)
3. Test that everything works

### For Production (Before Play Store):
1. Create a release keystore (Option 2 above)
2. Get the release SHA-1
3. Add BOTH debug and release SHA-1 to your API key:
   - Debug SHA-1: For local testing
   - Release SHA-1: For Play Store builds
4. Sign your app with the release keystore
5. Upload to Play Store

## Current Configuration

Your current setup:
- **Package name**: `com.sasri.parking.user`
- **Debug SHA-1**: `1C:BA:B0:FA:3E:20:BC:BE:21:8B:0B:6F:0B:AD:36:17:13:07:3E:E0`

You need to add:
- **Release SHA-1**: (Get it from your release keystore)

## How to Add Multiple SHA-1 Fingerprints

In Google Cloud Console API key settings:

1. Click "Add an item" for each SHA-1
2. Add entry:
   - Package: `com.sasri.parking.user`
   - SHA-1: `1C:BA:B0:FA:3E:20:BC:BE:21:8B:0B:6F:0B:AD:36:17:13:07:3E:E0` (Debug)
3. Click "Add an item" again
4. Add entry:
   - Package: `com.sasri.parking.user`
   - SHA-1: `<YOUR_RELEASE_SHA1_HERE>` (Release)
5. Save

Now your API key works for both development and production!

## Quick Solution for Testing RIGHT NOW

To unblock testing while you prepare for production:

1. **Temporarily remove restrictions** from the API key
2. Test your app fully
3. **Before uploading to Play Store**:
   - Create release keystore
   - Get release SHA-1
   - Add proper restrictions (debug + release SHA-1)
   - Re-sign your app
   - Upload to Play Store

## Security Best Practices

### ✅ DO:
- Use restricted API keys for production
- Add both debug and release SHA-1 fingerprints
- Keep your keystore file safe and backed up
- Use API restrictions (limit to specific APIs)

### ❌ DON'T:
- Upload to Play Store with unrestricted API key
- Share your keystore or passwords
- Commit API keys to public repositories
- Use the same key for multiple apps

## Example: Android App Restrictions

Your final configuration should look like:

```
Application restrictions: Android apps

Package name                    SHA-1 certificate fingerprint
com.sasri.parking.user         1C:BA:B0:FA:3E:20:BC:BE:21:8B:... (Debug)
com.sasri.parking.user         A5:D4:E2:F1:B3:C7:D8:E9:F0:A1:... (Release)
```

## Need Help?

If you need to create a keystore or get the SHA-1, run these commands:

```bash
# Create keystore (one time only)
keytool -genkey -v -keystore ~/parking-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias parking-key

# Get SHA-1
keytool -list -v -keystore ~/parking-release-key.jks -alias parking-key
```

Store the keystore file and password safely - you'll need them for every Play Store update!
