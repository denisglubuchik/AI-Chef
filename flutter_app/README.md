# Holodilnik Flutter App

Kitchen assistant mobile application for ingredient detection and recipe suggestions.

## Architecture

The app follows a **simplified clean architecture** pattern with clear separation of concerns:

```
lib/
├── main.dart                    # App entry point
├── routes.dart                  # Route constants
├── splash_page.dart            # Splash screen
├── core/
│   ├── constants.dart          # App-wide constants (API URLs, etc.)
│   └── widgets/                # Shared widgets
│       ├── loading_indicator.dart
│       ├── error_view.dart
│       └── empty_state.dart
├── models/                      # Data models
│   ├── ingredient.dart
│   ├── recipe.dart
│   └── suggestion.dart
├── services/                    # Business logic & API calls
│   ├── recipe_service.dart     # Recipe API operations
│   ├── auth_service.dart       # Authentication
│   └── favorites_service.dart  # Favorites management
└── screens/                     # UI screens
    ├── auth/
    │   ├── sign_in_screen.dart
    │   └── sign_up_screen.dart
    ├── recipe_search/
    │   ├── recipe_search_screen.dart
    │   └── widgets/            # Screen-specific widgets
    │       ├── ingredient_input_card.dart
    │       ├── image_preview_card.dart
    │       └── suggestion_list.dart
    ├── recipe_detail/
    │   └── recipe_detail_screen.dart
    └── profile/
        └── profile_screen.dart
```

## Key Features

✅ **Service Layer** - All business logic separated from UI  
✅ **Clean Models** - Reusable data classes with JSON serialization  
✅ **Shared Widgets** - Consistent UI components  
✅ **Error Handling** - Proper exception handling with user feedback  
✅ **Simple State** - Uses `setState()` - no complex state management needed  

## Architecture Benefits

### No Complex State Management
This app uses Flutter's built-in `setState()` for state management. For this project size, it's:
- ✅ **Simple** - Easy to understand
- ✅ **Sufficient** - Handles all our needs
- ✅ **No Learning Curve** - Standard Flutter
- ✅ **Less Boilerplate** - No extra libraries

### Service Layer Pattern
All API calls and business logic are in service classes:

```dart
// Example: Using RecipeService
final recipeService = RecipeService();
final suggestions = await recipeService.getSuggestions(
  ingredients: ['томат', 'курица'],
);
```

Benefits:
- Easy to test (can mock services)
- Reusable across screens
- Clean separation from UI

### Model Classes
All data is represented by proper models:

```dart
// Example: Recipe model
final recipe = Recipe.fromJson(jsonData);
print(recipe.totalTimeMinutes); // Computed property
```

Benefits:
- Type-safe
- Easy JSON conversion
- Computed properties
- Code completion

## Setup

1. **Install dependencies:**
   ```bash
   cd flutter_app
   flutter pub get
   ```

2. **Configure environment:**
   Create a `.env` file:
   ```
   SUPABASE_URL=your-supabase-url
   SUPABASE_ANON_KEY=your-anon-key
   ```

3. **Configure API URL:**
   Edit `lib/core/constants.dart` or use environment variable:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://your-backend:8000
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## Services

### RecipeService
Handles all recipe-related API operations:
- `extractIngredients(XFile)` - Extract from image
- `getSuggestions(...)` - Get meal suggestions
- `buildRecipe(...)` - Build detailed recipe
- `extractAndSuggest(...)` - Combined operation

### AuthService
Manages authentication:
- `signIn(email, password)` - Sign in user
- `signUp(email, password)` - Register user
- `signOut()` - Sign out user
- `isAuthenticated` - Check auth status

### FavoritesService
Manages favorite recipes:
- `addFavorite(Recipe)` - Save to favorites
- `removeFavoriteById(id)` - Remove favorite
- `getFavorites()` - Get all favorites
- `isFavorite(title)` - Check if favorited

## State Management Philosophy

We use **simple local state** with `setState()` because:

1. **App is Simple** - No complex global state needs
2. **Services Handle Logic** - Business logic in services, not widgets
3. **Local State Works** - Each screen manages its own state
4. **Easy to Understand** - Standard Flutter patterns

Example:
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _service = RecipeService();
  List<Recipe> _recipes = [];
  bool _isLoading = false;

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final recipes = await _service.getSuggestions(...);
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
    }
  }
}
```

## Screens

### Recipe Search Screen
- Upload photo or enter ingredients manually
- Image recognition with progress feedback
- View meal suggestions
- Navigate to recipe details

### Recipe Detail Screen
- View full recipe with steps
- See ingredients and equipment
- Add/remove from favorites
- Step-by-step instructions with tips

### Profile Screen
- View user info
- Browse favorite recipes
- Delete favorites
- Sign out

### Auth Screens
- Sign in / Sign up
- Email/password authentication
- Proper error handling

## Error Handling

All services throw custom exceptions:
- `RecipeServiceException` - API errors
- `AuthServiceException` - Auth errors
- `FavoritesServiceException` - Database errors

Screens catch and display errors to users with helpful messages.

## Development Tips

### Adding a New Screen
1. Create in `lib/screens/your_feature/`
2. Create service if needed in `lib/services/`
3. Use shared widgets from `lib/core/widgets/`
4. Add route to `lib/routes.dart` and `lib/main.dart`

### Adding a New API Call
1. Add method to appropriate service
2. Define models if needed
3. Handle errors properly
4. Use in screen with `setState()`

### Testing Locally
```bash
# Run backend
cd backend
uvicorn main:app --reload

# Run Flutter (pointing to local backend)
cd flutter_app
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

## Common Patterns

### Loading State
```dart
bool _isLoading = false;

Future<void> _loadData() async {
  setState(() => _isLoading = true);
  try {
    // Load data
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Error Handling
```dart
try {
  await service.doSomething();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### Navigation
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => DetailScreen(data: data),
  ),
);
```

## Next Steps

If the app grows, consider:
- [ ] Add caching with shared_preferences
- [ ] Add offline support
- [ ] Add proper state management (Riverpod/Bloc) if needed
- [ ] Add tests
- [ ] Add analytics

But for now, the simple approach works great! 🎉
