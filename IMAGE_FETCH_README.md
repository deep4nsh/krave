# Automatic Image Fetching for Menu Items

## ✅ API Configuration Status

Your Google Custom Search API keys in `assets/secrets.properties` are **working correctly**!

### API Credentials
- **Engine ID**: `a43ca7f09a623425a`
- **API Key**: `AIzaSyCGBgUYwS0IoWg-rj7NU1PK9711K30QZ3U`

### Test Results
All test queries successfully returned images:
- ✅ pizza → Found
- ✅ burger → Found  
- ✅ pasta → Found
- ✅ biryani → Found
- ✅ dosa → Found

## 🚀 Features Implemented

### 1. **Automatic Image Fetching on Menu Item Creation**
When you add a new menu item through the "Add Menu Item" dialog, the app automatically:
1. Searches for an image based on the item name
2. Downloads the image URL from Google Custom Search
3. Saves the image URL to Firestore with the menu item

**Location**: `lib/src/screens/owner/manage_menu.dart` (lines 50-87)

### 2. **Batch Image Fetching for Existing Items**
New magic button (✨) in the menu management screen that:
1. Finds all menu items without images
2. Automatically fetches images for each item
3. Updates Firestore with the new image URLs
4. Shows progress and results

**How to use**: 
- Open the "Manage Menu" screen
- Click the sparkle/magic icon (✨) in the app bar
- The app will automatically fetch images for all items missing them

**Location**: `lib/src/screens/owner/manage_menu.dart` (lines 19-62)

### 3. **Enhanced Image Search Service**
Added new capabilities:
- Better error logging for debugging
- Batch search functionality for multiple items
- Rate limiting protection (500ms delay between requests)

**Location**: `lib/src/services/image_search_service.dart`

## 📁 Files Modified

1. **`lib/src/services/image_search_service.dart`**
   - Added `searchImages()` method for batch processing
   - Enhanced error logging

2. **`lib/src/screens/owner/manage_menu.dart`**
   - Added `_batchFetchImages()` method
   - Added app bar with magic button (✨)
   - Added loading indicator during batch fetch

3. **`test_api.sh`** (NEW)
   - Test script to verify API functionality
   - Tests multiple food item queries

## 🧪 Testing the API

Run the test script to verify API functionality:

```bash
./test_api.sh
```

This will test the API with sample food items (pizza, burger, pasta, biryani, dosa).

## 📝 How It Works

### Image Search Flow
1. API keys are loaded from `assets/secrets.properties` at app startup
2. When a menu item is added or batch fetch is triggered:
   - The item name (e.g., "Paneer Tikka") is sent to Google Custom Search API
   - The API returns image URLs matching the query
   - The first image URL is saved to Firestore under the `photoUrl` field
3. Images are displayed using `CachedNetworkImage` for better performance

### Data Structure
```dart
MenuItemModel {
  id: String,
  name: String,         // Used as search query
  price: int,
  available: bool,
  category: String?,
  photoUrl: String?,    // Auto-fetched image URL stored here
}
```

## ⚠️ Important Notes

1. **Rate Limiting**: Google Custom Search API has usage limits
   - Free tier: 100 queries/day
   - Consider upgrading if you need more
   - The app adds 500ms delay between requests to avoid hitting rate limits

2. **Image Quality**: 
   - Results depend on Google's search algorithm
   - More specific item names yield better results
   - Example: "Paneer Tikka Masala" is better than just "Paneer"

3. **Error Handling**:
   - If an image isn't found, the item will have a placeholder icon
   - Failed searches don't block item creation
   - Error messages are logged for debugging

## 🔐 Security Notes

The API key is stored in `assets/secrets.properties` and bundled with the app. For production:
- Consider using environment variables or secure storage
- Implement backend API proxy to hide keys
- Monitor API usage in Google Cloud Console
- Set up API key restrictions (HTTP referrers, IP addresses)

## 🎯 Usage Tips

1. **For Best Results**:
   - Use clear, descriptive item names
   - Include cuisine type for better matches (e.g., "Italian Pizza" vs "Pizza")
   - Test the image search with the test script first

2. **Managing Images**:
   - Images are cached by `CachedNetworkImage` for performance
   - You can manually update `photoUrl` in Firestore if needed
   - Delete and re-add items to fetch new images

3. **Troubleshooting**:
   - Check Flutter console for error messages
   - Verify internet connectivity
   - Run `test_api.sh` to confirm API is working
   - Check Google Cloud Console for quota limits

## 📊 API Usage Monitoring

Monitor your API usage at:
https://console.cloud.google.com/apis/api/customsearch.googleapis.com

Current setup ID: `a43ca7f09a623425a`

## 🛠️ Future Enhancements

Potential improvements:
- [ ] Image upload from device as alternative to auto-fetch
- [ ] Image editing/cropping before save
- [ ] Multiple image options to choose from
- [ ] Image caching optimization
- [ ] Retry mechanism for failed searches
- [ ] Progress bar showing individual item fetch status
