# Keystore Generation Guide for QuickPark App

## CRITICAL: You MUST generate a keystore before publishing to Play Store!

Your keystore is your permanent identity for this app. If you lose it, you can NEVER update your app on the Play Store again. You'll have to publish as a completely new app.

---

## Step 1: Generate the Keystore

Open a terminal/command prompt and navigate to the `android` directory of your project:

```bash
cd c:\Users\msi\Desktop\project\parking\android
```

Run the following command to generate your keystore:

```bash
keytool -genkey -v -keystore quickpark-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quickpark-key
```

You will be prompted to enter:

1. **Keystore password**: Choose a strong password (you'll need this forever!)
2. **Key password**: Can be the same as keystore password or different
3. **Your name** (or organization)
4. **Organizational unit** (optional, can press Enter)
5. **Organization name** (your company name)
6. **City or Locality**
7. **State or Province**
8. **Country Code** (2-letter code, e.g., US, IN, UK)

### Example:
```
Enter keystore password: MySecurePassword123!
Re-enter new password: MySecurePassword123!
What is your first and last name?
  [Unknown]:  John Doe
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  QuickPark Inc
What is the name of your City or Locality?
  [Unknown]:  San Francisco
What is the name of your State or Province?
  [Unknown]:  California
What is the two-letter country code for this unit?
  [Unknown]:  US
Is CN=John Doe, OU=Development, O=QuickPark Inc, L=San Francisco, ST=California, C=US correct?
  [no]:  yes

Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,000 days
        for: CN=John Doe, OU=Development, O=QuickPark Inc, L=San Francisco, ST=California, C=US
Enter key password for <quickpark-key>
        (RETURN if same as keystore password):
[Storing quickpark-release-key.jks]
```

---

## Step 2: Create key.properties File

Create a file named `key.properties` in the `android` directory (NOT in the `app` subdirectory).

**Path:** `c:\Users\msi\Desktop\project\parking\android\key.properties`

Add the following content (replace with your actual passwords):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=quickpark-key
storeFile=../quickpark-release-key.jks
```

**Example:**
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=quickpark-key
storeFile=../quickpark-release-key.jks
```

---

## Step 3: Verify .gitignore

Make sure these files are in your `.gitignore`:

```
# Keystore files - NEVER commit these!
*.jks
*.keystore
key.properties
```

Check if already added:
```bash
cat .gitignore | grep -E '\.jks|key\.properties'
```

If not present, add them to `.gitignore`.

---

## Step 4: Get SHA-1 Fingerprint (for Google Sign-In)

You need the SHA-1 fingerprint from your release keystore for Google Sign-In to work in production.

Run this command:

```bash
keytool -list -v -keystore quickpark-release-key.jks -alias quickpark-key
```

Enter your keystore password when prompted.

Look for the line that says:
```
Certificate fingerprints:
     SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE
     SHA256: ...
```

**Copy the SHA1 fingerprint** (the line starting with SHA1:).

---

## Step 5: Update Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to **APIs & Services > Credentials**
4. Find your **OAuth 2.0 Client ID** for Android
5. Add your **SHA-1 fingerprint** from Step 4
6. Add your package name: `com.sasri.parking.user`
7. Save

---

## Step 6: Update Google Maps API Key Restrictions

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Go to **APIs & Services > Credentials**
3. Find your **Google Maps API Key** (currently: AIzaSyBHQio6c2Lxi8WE62qqPiksOI8bciKDk2k)
4. Click **Edit**
5. Under **Application restrictions**, select **Android apps**
6. Click **Add an item**
7. Add:
   - Package name: `com.sasri.parking.user`
   - SHA-1 fingerprint: (paste from Step 4)
8. Save

**SECURITY TIP:** Consider creating a separate API key for production vs development.

---

## Step 7: Backup Your Keystore

**THIS IS CRITICAL!**

1. Copy `quickpark-release-key.jks` to a secure location:
   - External hard drive
   - Encrypted USB drive
   - Secure cloud storage (encrypted)
   - Password manager with file storage

2. Save your `key.properties` passwords securely:
   - Password manager
   - Encrypted document
   - Physical safe

3. **NEVER LOSE THESE FILES!** Without them:
   - You cannot update your app
   - You cannot publish new versions
   - You'll have to create a new app listing

---

## Step 8: Test Release Build

After setting up the keystore, test that release builds work:

```bash
cd c:\Users\msi\Desktop\project\parking
flutter clean
flutter build appbundle --release
```

If successful, you'll see:
```
✓ Built build\app\outputs\bundle\release\app-release.aab
```

---

## Troubleshooting

### Error: "Keystore file not found"
- Check that `storeFile` path in `key.properties` is correct
- Should be `../quickpark-release-key.jks` (relative to `android/app/` directory)
- Keystore should be in `android/` directory

### Error: "Wrong password"
- Double-check passwords in `key.properties`
- Ensure no extra spaces or quotes

### Error: "keytool: command not found"
- On Windows, make sure Java JDK is installed
- Add Java bin directory to PATH
- Typically: `C:\Program Files\Android\Android Studio\jbr\bin`

### Build still using debug keystore
- Make sure `key.properties` file exists in `android/` directory
- Check that build.gradle.kts correctly references the signing config
- Clean and rebuild: `flutter clean && flutter build appbundle --release`

---

## Security Checklist

- [ ] Keystore generated with strong password
- [ ] key.properties created with correct values
- [ ] *.jks and key.properties added to .gitignore
- [ ] Keystore backed up in 2+ secure locations
- [ ] Passwords saved in password manager
- [ ] SHA-1 fingerprint added to Google Cloud Console
- [ ] Google Maps API key restricted to your package + SHA-1
- [ ] OAuth credentials updated with release SHA-1
- [ ] Never committed keystore or passwords to Git

---

## Quick Reference Commands

```bash
# Generate keystore
keytool -genkey -v -keystore quickpark-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quickpark-key

# Get SHA-1 fingerprint
keytool -list -v -keystore quickpark-release-key.jks -alias quickpark-key

# Build release AAB
flutter build appbundle --release

# Build release APK (for testing)
flutter build apk --release

# Install release build on device
flutter install --release
```

---

## Next Steps

After completing keystore setup:
1. Update Google Cloud Console credentials (Steps 5 & 6)
2. Build release AAB
3. Test on real device
4. Continue with Play Store submission checklist
