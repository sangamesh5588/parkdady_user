# Google Places API Setup Guide

## Current Configuration
- **API Key**: `AIzaSyD5ZG8yheuA88UsmYT0fs2Xst5-75tyqKQ`
- **Configuration File**: `lib/core/config.dart`
- **Service File**: `lib/services/places_service.dart`

## Required Google Cloud APIs

Your Google Maps API key needs the following APIs enabled:

### 1. Places API (New)
- **Purpose**: For autocomplete suggestions when user types in search bar
- **Endpoint Used**: `/place/autocomplete/json`
- **Enable at**: https://console.cloud.google.com/apis/library/places-backend.googleapis.com

### 2. Places API - Place Details
- **Purpose**: To get coordinates (latitude/longitude) from selected place
- **Endpoint Used**: `/place/details/json`
- **Enable at**: https://console.cloud.google.com/apis/library/places-backend.googleapis.com

### 3. Geocoding API
- **Purpose**: For reverse geocoding (converting coordinates to addresses)
- **Enable at**: https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com

## How to Enable APIs

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services** > **Library**
4. Search for each API mentioned above
5. Click **Enable** for each API

## How the Search Works

### Step 1: User Types in Search Bar
```dart
// User types "Koramangala"
_onSearchQueryChanged("Koramangala")
  ↓
// After 300ms debounce
_fetchPlaceSuggestions("Koramangala")
  ↓
// Calls Google Places Autocomplete API
PlacesService.getPlaceSuggestions("Koramangala")
  ↓
// Returns list of suggestions
[
  "Koramangala, Bangalore, Karnataka, India",
  "Koramangala 1st Block, Bangalore",
  "Koramangala 4th Block, Bangalore",
  ...
]
```

### Step 2: User Selects a Suggestion
```dart
_onSuggestionSelected(suggestion)
  ↓
// Gets place details with coordinates
PlacesService.getPlaceDetails(placeId)
  ↓
// Returns coordinates
{
  latitude: 12.9352,
  longitude: 77.6245,
  name: "Koramangala",
  ...
}
  ↓
// Searches for nearby parking
_searchNearbyParking(lat, lng, locationName)
  ↓
// Shows parking results on screen
```

## Testing the Search

1. **Open the app**
2. **Navigate to Search tab** (bottom navigation)
3. **Type in the search bar**: Try typing "Koramangala" or "Indiranagar"
4. **Watch the console logs**: You should see debug prints like:
   ```
   🔤 Search query changed: "Koram"
   ⏱️ Starting debounce timer (300ms)
   ✅ Debounce timer completed, fetching suggestions
   🔍 Fetching place suggestions for: Koram
   📡 Response status: 200
   ✅ Found 5 suggestions
   ```

## Troubleshooting

### Error: "REQUEST_DENIED"
**Cause**: Places API not enabled for this API key
**Solution**: Enable "Places API (New)" in Google Cloud Console

### Error: "INVALID_REQUEST"
**Cause**: Missing required parameters or incorrect API endpoint
**Solution**: Check that the API key is correct in `lib/core/config.dart`

### Error: "OVER_QUERY_LIMIT"
**Cause**: You've exceeded your daily quota
**Solution**:
- Check usage in Google Cloud Console
- Enable billing if needed
- Set up API key restrictions

### No suggestions appear
**Possible Causes**:
1. Internet connection issue
2. API key not enabled
3. API restrictions blocking requests

**How to Debug**:
1. Check Flutter console for error messages
2. Look for prints starting with 🔍, 📡, ✅, or ❌
3. Verify API key in Google Cloud Console

## API Key Restrictions (Recommended)

For production, add these restrictions in Google Cloud Console:

### Application Restrictions
- **Android apps**: Add your app's package name and SHA-1 certificate fingerprint
- **iOS apps**: Add your app's bundle identifier

### API Restrictions
- Restrict to only these APIs:
  - Places API
  - Geocoding API
  - (Any other maps-related APIs you're using)

## Current Features

✅ **Working Features**:
- Search bar with Google Places Autocomplete
- Debounced API calls (300ms delay)
- Place selection with coordinate fetching
- Nearby parking search based on selected location
- Popular area quick search (Koramangala, Indiranagar, etc.)
- Loading states and error handling
- Suggestion dropdown UI

✅ **Recent Updates**:
- Removed map toggle button
- Added better error messages
- Cleaned up unused imports
- Improved user feedback

## Next Steps

1. **Test the search functionality** by typing different locations
2. **Check console logs** to verify API calls are working
3. **Enable required APIs** if you see any errors
4. **Set up billing** in Google Cloud if needed (Places API requires it)

---

**Note**: The Places API requires billing to be enabled in your Google Cloud project, even if you're using the free tier. Make sure billing is set up to avoid "REQUEST_DENIED" errors.
