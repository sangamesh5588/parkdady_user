# Instructions for Renter App AI

## Context
I have a parking platform with TWO apps sharing the SAME database:
- **Host App** (already implemented) - for parking space owners
- **Renter App** (this app) - for people looking to rent parking spaces

Users can use BOTH apps with the same login credentials.

## Database Structure

The `profiles` table has dual role tracking:

```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  phone TEXT,
  role TEXT,  -- Legacy field (nullable, can ignore)
  is_renter BOOLEAN DEFAULT FALSE,  -- TRUE when user uses renter app
  is_host BOOLEAN DEFAULT FALSE,    -- TRUE when user uses host app
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  permissions_granted JSONB DEFAULT '{}'
);
```

## What I Need You to Do

### Task 1: Update Auth Service

In my `auth_service.dart`, I already have these methods available:

```dart
// Enable renter functionality (needs to be called)
Future<void> enableRenterRole() async {
  if (currentUser == null) return;

  try {
    await _supabase
        .from('profiles')
        .update({'is_renter': true})
        .eq('id', currentUser!.id);
  } catch (e) {
    print('Error enabling renter role: $e');
    rethrow;
  }
}

// Check if user is a renter
Future<bool> isRenter() async {
  if (currentUser == null) return false;

  try {
    final response = await _supabase
        .from('profiles')
        .select('is_renter')
        .eq('id', currentUser!.id)
        .maybeSingle();

    return response?['is_renter'] ?? false;
  } catch (e) {
    return false;
  }
}
```

**Please add these methods to my auth_service.dart if they don't exist.**

### Task 2: Update main.dart

In my `main.dart`, in the `_getInitialScreen` function, when a user is authenticated, I need to **automatically enable renter role**.

Find this code:
```dart
Future<Widget> _getInitialScreen(bool isAuthenticated) async {
  if (!isAuthenticated) {
    return const SplashScreen();
  }

  // Authenticated - check onboarding and permissions
  try {
    final hasCompletedOnboarding = await _authService.hasCompletedOnboarding();
    // ... rest of the code
  }
}
```

**Change it to:**
```dart
Future<Widget> _getInitialScreen(bool isAuthenticated) async {
  if (!isAuthenticated) {
    return const SplashScreen();
  }

  // Authenticated - enable renter role for this app
  try {
    // Enable renter functionality when user logs into RENTER app
    await _authService.enableRenterRole();

    final hasCompletedOnboarding = await _authService.hasCompletedOnboarding();
    // ... rest of the code
  }
}
```

### Task 3: Update Comments

Update all comments in signup and login screens from:
- ❌ "User role is automatically set as 'renter' during signup"
- ❌ "Role will be set when auth state changes"

To:
- ✅ "User role is automatically set as 'renter' when using RENTER app"
- ✅ "User will be treated as 'renter' in this RENTER app"

### Task 4: Update getUserProfile Method

In `auth_service.dart`, update the `getUserProfile()` method to return `is_renter` and `is_host` instead of just `role`:

```dart
Future<Map<String, dynamic>?> getUserProfile() async {
  if (currentUser == null) return null;

  try {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();

    final authProvider = getAuthProvider();
    final userMetadata = currentUser!.userMetadata ?? {};

    if (response == null) {
      return {
        'id': currentUser!.id,
        'email': currentUser!.email,
        'is_renter': false,
        'is_host': false,
        'auth_provider': authProvider,
        'full_name': userMetadata['full_name'] ?? '',
        'phone_number': userMetadata['phone_number'] ?? '',
        'created_at': currentUser!.createdAt,
        'last_sign_in': currentUser!.lastSignInAt,
      };
    }

    return {
      ...response,
      'auth_provider': authProvider,
      'full_name': response['full_name'] ?? userMetadata['full_name'] ?? '',
      'phone_number': response['phone_number'] ?? userMetadata['phone_number'] ?? '',
      'last_sign_in': currentUser!.lastSignInAt,
    };
  } catch (e) {
    return {
      'id': currentUser!.id,
      'email': currentUser!.email,
      'is_renter': false,
      'is_host': false,
      'auth_provider': getAuthProvider(),
      'full_name': currentUser!.userMetadata?['full_name'] ?? '',
      'phone_number': currentUser!.userMetadata?['phone_number'] ?? '',
      'created_at': currentUser!.createdAt,
      'last_sign_in': currentUser!.lastSignInAt,
    };
  }
}
```

## How It Will Work

After these changes:

1. **User logs into RENTER app** → `is_renter` is set to TRUE automatically
2. **User logs into HOST app** → `is_host` is set to TRUE automatically
3. **Same user uses BOTH apps** → Both `is_renter=TRUE` and `is_host=TRUE`

## Database Notes

- The database is **already set up** with `is_renter` and `is_host` columns
- The trigger no longer sets a default role
- Each app (Renter/Host) manages its own role flag
- Users can be renters, hosts, or BOTH!

## Summary

Please make these changes to the RENTER app so that:
1. ✅ When users log in, `is_renter` is automatically set to TRUE
2. ✅ The auth service has methods to check renter status
3. ✅ Comments reflect that this is the RENTER app (not host)
4. ✅ getUserProfile returns dual role information

This mirrors the exact implementation done in the HOST app, but for renters!
