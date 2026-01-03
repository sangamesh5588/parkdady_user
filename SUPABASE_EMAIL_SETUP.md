# Supabase Email Verification Setup with Resend

This guide will help you configure Supabase to use Resend for sending email verification emails.

## What's Already Implemented

The following code changes have been completed:

1. **Email Verification Screen** (`lib/presentation/pages/login/email_verification_screen.dart`)
   - Beautiful UI showing verification instructions
   - Resend verification email button
   - "I've Verified" button to check verification status
   - Automatic navigation after verification

2. **Auth Provider Updates** (`lib/presentation/providers/auth_provider.dart`)
   - `resendVerificationEmail(String email)` function
   - Calls Supabase `auth.resend()` with OtpType.signup

3. **Signup Flow** (`lib/presentation/pages/signup/signup_screen.dart`)
   - Now navigates to EmailVerificationScreen after successful signup
   - Passes user's email to the verification screen

4. **Login Flow** (`lib/presentation/pages/login/login_screen.dart`)
   - Detects "email not confirmed" errors
   - Shows "Resend" button in error message
   - Resends verification email on tap

## Supabase Configuration Steps

### Step 1: Enable Email Confirmations

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** → **Settings**
3. Scroll down to **Email Auth**
4. Enable **"Confirm email"** toggle
5. Click **Save**

### Step 2: Configure Resend as Email Provider

#### Option A: Use Resend (Recommended for Production)

1. Sign up for a free Resend account at [resend.com](https://resend.com)
2. Verify your domain or use Resend's testing domain
3. Generate an API key from the Resend dashboard
4. In Supabase dashboard:
   - Go to **Project Settings** → **Auth** → **SMTP Settings**
   - Enable **"Use custom SMTP server"**
   - Enter the following settings:
     - **Host**: `smtp.resend.com`
     - **Port**: `465` (or `587` for TLS)
     - **Username**: `resend`
     - **Password**: Your Resend API key
     - **Sender email**: Your verified email (e.g., `noreply@yourdomain.com`)
     - **Sender name**: `Park Daddy` (or your app name)
5. Click **Save**

#### Option B: Use Supabase Default (For Testing Only)

Supabase provides default email service for testing, but it has limitations:
- Rate limited
- May go to spam
- Not recommended for production

If using default:
1. Just ensure "Confirm email" is enabled (Step 1)
2. Supabase will use its built-in email service

### Step 3: Configure Email Templates

1. In Supabase dashboard, go to **Authentication** → **Email Templates**
2. Click on **"Confirm signup"** template
3. Customize the template (optional):
   ```html
   <h2>Welcome to Park Daddy!</h2>
   <p>Thanks for signing up. Please verify your email address by clicking the link below:</p>
   <p><a href="{{ .ConfirmationURL }}">Verify Email Address</a></p>
   <p>Or copy and paste this URL into your browser:</p>
   <p>{{ .ConfirmationURL }}</p>
   <p>This link expires in 24 hours.</p>
   <p>If you didn't create an account, you can safely ignore this email.</p>
   ```
4. Make sure the **Confirmation URL** contains: `{{ .ConfirmationURL }}`
5. Click **Save**

### Step 4: Configure Redirect URLs

1. In Supabase dashboard, go to **Authentication** → **URL Configuration**
2. Add your app's deep link URL to **Redirect URLs**:
   - Add: `io.supabase.parkingapp://login-callback`
3. This ensures users are redirected back to your app after email verification
4. Click **Save**

### Step 5: Test Email Verification Flow

1. **Sign up a new user**:
   - Open your app
   - Go to Sign Up screen
   - Enter test email and create account
   - You should see the Email Verification Screen

2. **Check your email**:
   - Open the email inbox
   - Look for verification email (check spam if not found)
   - Click the verification link

3. **Complete verification**:
   - After clicking the link, return to the app
   - Tap "I've Verified My Email" button
   - You should be logged in and navigated to the main app

4. **Test resend functionality**:
   - On the verification screen, tap "Resend"
   - Check that you receive another verification email
   - Verify the resend works correctly

## Troubleshooting

### Emails Not Being Sent

**Problem**: User doesn't receive verification email

**Solutions**:
1. Check spam/junk folder
2. Verify SMTP settings are correct in Supabase
3. Check Resend dashboard for delivery logs
4. Ensure sender email is verified in Resend
5. Check Supabase logs for email sending errors

### "Email Not Confirmed" Error on Login

**Problem**: User tries to login but gets "email not confirmed" error

**Solutions**:
1. This is correct behavior - user needs to verify email first
2. User should see "Resend" button in the error message
3. Click "Resend" to get a new verification email
4. Or go back to signup and create a new verification request

### Deep Link Not Working

**Problem**: After clicking verification link, user is not redirected to app

**Solutions**:
1. Ensure redirect URL is added to Supabase (Step 4)
2. Check that deep link is configured in Android/iOS:
   - Android: Check `android/app/src/main/AndroidManifest.xml`
   - iOS: Check `ios/Runner/Info.plist`
3. Test deep link with: `adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.parkingapp://login-callback"`

### Verification Link Expired

**Problem**: User clicks verification link but it's expired

**Solutions**:
1. Verification links expire in 24 hours by default
2. User should tap "Resend" on the verification screen
3. Or try logging in to trigger the "Resend" option

### User Gets Logged In Immediately After Signup

**Problem**: User is auto-logged in without verifying email

**Solutions**:
1. Check that "Confirm email" is enabled in Supabase Auth settings
2. Verify the email confirmation template is active
3. Check Supabase auth logs for any errors

## Production Checklist

Before going to production, ensure:

- [ ] Resend account is set up with verified domain
- [ ] SMTP settings are configured in Supabase
- [ ] Email confirmation is enabled in Supabase
- [ ] Email templates are customized with branding
- [ ] Redirect URLs are configured for production domain
- [ ] Deep links are tested on both Android and iOS
- [ ] Spam score is tested using [mail-tester.com](https://www.mail-tester.com)
- [ ] Rate limits are appropriate for your expected user volume
- [ ] Email delivery is monitored in Resend dashboard

## Additional Resources

- [Supabase Email Documentation](https://supabase.com/docs/guides/auth/auth-email)
- [Resend Documentation](https://resend.com/docs)
- [Supabase Auth Helpers](https://supabase.com/docs/guides/auth/auth-helpers)
- [Deep Linking in Flutter](https://docs.flutter.dev/development/ui/navigation/deep-linking)

## Support

If you encounter issues:
1. Check Supabase auth logs in dashboard
2. Check Resend delivery logs
3. Review email template configuration
4. Test with different email providers (Gmail, Outlook, etc.)
