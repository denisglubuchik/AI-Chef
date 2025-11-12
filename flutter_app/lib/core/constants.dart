/// Application constants and configuration
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api/$apiVersion';

  // API Endpoints
  static const String extractIngredientsEndpoint =
      '$apiPrefix/extract-ingredients';
  static const String suggestMealsEndpoint = '$apiPrefix/suggest-meals';
  static const String buildRecipeEndpoint = '$apiPrefix/build-recipe';
  static const String extractAndSuggestEndpoint =
      '$apiPrefix/extract-and-suggest';

  // Image Configuration
  static const int maxImageSizeMB = 20;
  static const double imageQuality = 85;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;

  // Private constructor to prevent instantiation
  AppConstants._();
}
