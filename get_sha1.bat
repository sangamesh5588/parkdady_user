@echo off
echo Getting SHA-1 fingerprint for debug keystore...
echo.

cd %USERPROFILE%\.android

echo Debug Keystore SHA-1:
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr "SHA1:"

echo.
echo Copy the SHA1 fingerprint above and add it to your Google Cloud Console API key restrictions.
echo.
pause
