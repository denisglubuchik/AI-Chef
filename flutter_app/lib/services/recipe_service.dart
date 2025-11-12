import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../core/constants.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/suggestion.dart';

class RecipeService {
  final String baseUrl;
  final http.Client? client;

  RecipeService({String? baseUrl, this.client})
    : baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  http.Client get _client => client ?? http.Client();

  /// Extract ingredients from image
  Future<IngredientExtractionResult> extractIngredients(XFile image) async {
    try {
      final url = Uri.parse(
        '$baseUrl${AppConstants.extractIngredientsEndpoint}',
      );

      // Read image bytes
      final bytes = await image.readAsBytes();

      // Determine MIME type
      String mimeType = 'image/jpeg';
      final fileName = image.name.toLowerCase();
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: image.name,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IngredientExtractionResult.fromJson(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is RecipeServiceException) rethrow;
      throw RecipeServiceException('Failed to extract ingredients: $e');
    }
  }

  /// Get meal suggestions
  Future<List<RecipeSuggestion>> getSuggestions({
    required List<String> ingredients,
    int? servings,
    List<String>? dietaryPreferences,
  }) async {
    try {
      final url = Uri.parse('$baseUrl${AppConstants.suggestMealsEndpoint}');

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ingredients': ingredients,
          if (servings != null) 'servings': servings,
          if (dietaryPreferences != null)
            'dietary_preferences': dietaryPreferences,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dishes = data['dishes'] as List<dynamic>;
        return dishes
            .map(
              (dish) => RecipeSuggestion.fromJson(dish as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is RecipeServiceException) rethrow;
      throw RecipeServiceException('Failed to get suggestions: $e');
    }
  }

  /// Build detailed recipe
  Future<Recipe> buildRecipe({
    required String suggestionId,
    required String title,
    required String contextSummary,
    int? servings,
  }) async {
    try {
      final url = Uri.parse('$baseUrl${AppConstants.buildRecipeEndpoint}');

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'suggestion_id': suggestionId,
          'title': title,
          'context_summary': contextSummary,
          if (servings != null) 'servings': servings,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Recipe.fromJson(data);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is RecipeServiceException) rethrow;
      throw RecipeServiceException('Failed to build recipe: $e');
    }
  }

  /// Extract and suggest in one call (convenience method)
  Future<
    ({
      IngredientExtractionResult extraction,
      List<RecipeSuggestion> suggestions,
    })
  >
  extractAndSuggest({
    required XFile image,
    int? servings,
    List<String>? dietaryPreferences,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl${AppConstants.extractAndSuggestEndpoint}',
      );

      // Read image bytes
      final bytes = await image.readAsBytes();

      // Determine MIME type
      String mimeType = 'image/jpeg';
      final fileName = image.name.toLowerCase();
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: image.name,
          contentType: MediaType.parse(mimeType),
        ),
      );

      if (servings != null) {
        request.fields['servings'] = servings.toString();
      }
      if (dietaryPreferences != null && dietaryPreferences.isNotEmpty) {
        request.fields['dietary_preferences'] = dietaryPreferences.join(',');
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final extraction = IngredientExtractionResult.fromJson(
          data['extraction'],
        );
        final dishes = data['suggestions']['dishes'] as List<dynamic>;
        final suggestions = dishes
            .map(
              (dish) => RecipeSuggestion.fromJson(dish as Map<String, dynamic>),
            )
            .toList();

        return (extraction: extraction, suggestions: suggestions);
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is RecipeServiceException) rethrow;
      throw RecipeServiceException('Failed to extract and suggest: $e');
    }
  }

  /// Handle error responses
  RecipeServiceException _handleError(http.Response response) {
    String message = 'Ошибка ${response.statusCode}';

    try {
      final errorData = json.decode(response.body);
      if (errorData['detail'] != null) {
        message = errorData['detail'].toString();
      } else if (errorData['message'] != null) {
        message = errorData['message'].toString();
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        message = response.body;
      }
    }

    return RecipeServiceException(message, statusCode: response.statusCode);
  }
}

/// Custom exception for recipe service errors
class RecipeServiceException implements Exception {
  final String message;
  final int? statusCode;

  RecipeServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
