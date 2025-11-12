import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recipe.dart';

/// Service for managing favorite recipes
class FavoritesService {
  final SupabaseClient _supabase;

  FavoritesService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Check if a recipe is in favorites
  Future<bool> isFavorite(String recipeTitle) async {
    if (_userId == null) return false;

    try {
      final existing = await _supabase
          .from('favourite_recipes')
          .select('id')
          .eq('user_id', _userId!)
          .eq('title', recipeTitle)
          .maybeSingle();

      return existing != null;
    } catch (e) {
      throw FavoritesServiceException('Failed to check favorite status: $e');
    }
  }

  /// Add recipe to favorites
  Future<String> addFavorite(Recipe recipe) async {
    if (_userId == null) {
      throw FavoritesServiceException('User not authenticated');
    }

    try {
      final response = await _supabase
          .from('favourite_recipes')
          .insert({
            'user_id': _userId,
            'title': recipe.title,
            'data': recipe.toJson(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw FavoritesServiceException('Failed to add favorite: $e');
    }
  }

  /// Remove recipe from favorites by ID
  Future<void> removeFavoriteById(String favoriteId) async {
    try {
      await _supabase.from('favourite_recipes').delete().eq('id', favoriteId);
    } catch (e) {
      throw FavoritesServiceException('Failed to remove favorite: $e');
    }
  }

  /// Remove recipe from favorites by title
  Future<void> removeFavoriteByTitle(String recipeTitle) async {
    if (_userId == null) {
      throw FavoritesServiceException('User not authenticated');
    }

    try {
      await _supabase
          .from('favourite_recipes')
          .delete()
          .eq('user_id', _userId!)
          .eq('title', recipeTitle);
    } catch (e) {
      throw FavoritesServiceException('Failed to remove favorite: $e');
    }
  }

  /// Get all favorite recipes
  Future<List<FavoriteRecipe>> getFavorites() async {
    if (_userId == null) {
      throw FavoritesServiceException('User not authenticated');
    }

    try {
      final response = await _supabase
          .from('favourite_recipes')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => FavoriteRecipe.fromJson(item))
          .toList();
    } catch (e) {
      throw FavoritesServiceException('Failed to load favorites: $e');
    }
  }

  /// Get favorite ID by recipe title
  Future<String?> getFavoriteId(String recipeTitle) async {
    if (_userId == null) return null;

    try {
      final existing = await _supabase
          .from('favourite_recipes')
          .select('id')
          .eq('user_id', _userId!)
          .eq('title', recipeTitle)
          .maybeSingle();

      return existing?['id'] as String?;
    } catch (e) {
      return null;
    }
  }
}

/// Model for favorite recipe with metadata
class FavoriteRecipe {
  final String id;
  final String title;
  final Recipe recipe;
  final DateTime? createdAt;

  FavoriteRecipe({
    required this.id,
    required this.title,
    required this.recipe,
    this.createdAt,
  });

  factory FavoriteRecipe.fromJson(Map<String, dynamic> json) {
    return FavoriteRecipe(
      id: json['id'] as String,
      title: json['title'] as String,
      recipe: Recipe.fromJson(json['data'] as Map<String, dynamic>),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

/// Custom exception for favorites service errors
class FavoritesServiceException implements Exception {
  final String message;

  FavoritesServiceException(this.message);

  @override
  String toString() => message;
}
