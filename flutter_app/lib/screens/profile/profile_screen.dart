import 'package:flutter/material.dart';

import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/suggestion.dart';
import '../../services/auth_service.dart';
import '../../services/favorites_service.dart';
import '../../routes.dart';
import '../recipe_detail/recipe_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _searchController = TextEditingController();

  List<FavoriteRecipe> _favorites = [];
  List<FavoriteRecipe> _filteredFavorites = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchController.addListener(_filterFavorites);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFavorites() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFavorites = _favorites;
      } else {
        _filteredFavorites = _favorites.where((favorite) {
          final titleMatch = favorite.recipe.title.toLowerCase().contains(
            query,
          );
          final descMatch = favorite.title.toLowerCase().contains(query);
          return titleMatch || descMatch;
        }).toList();
      }
    });
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final favorites = await _favoritesService.getFavorites();

      if (!mounted) return;

      setState(() {
        _favorites = favorites;
        _filteredFavorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFavorite(FavoriteRecipe favorite) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из избранного?'),
        content: Text('Вы уверены, что хотите удалить "${favorite.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _favoritesService.removeFavoriteById(favorite.id);

      if (!mounted) return;

      setState(() {
        _favorites.removeWhere((f) => f.id == favorite.id);
        _filterFavorites();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Рецепт удален из избранного'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Routes.signin, (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка выхода: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openRecipe(FavoriteRecipe favorite) {
    final suggestion = RecipeSuggestion(
      suggestionId: favorite.recipe.suggestionId,
      title: favorite.recipe.title,
      description: favorite.title,
    );

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              suggestion: suggestion,
              cachedRecipe: favorite.recipe,
            ),
          ),
        )
        .then((_) => _loadFavorites()); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Column(
        children: [
          // User info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF1B4D3E).withOpacity(0.1),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF1B4D3E),
                  child: Text(
                    (user?.email ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Color(0xFFF5E6D3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? 'Неизвестный пользователь',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Section title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFF1B4D3E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Избранные рецепты (${_filteredFavorites.length}${_searchQuery.isNotEmpty ? ' из ${_favorites.length}' : ''})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search field
          if (_favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск рецептов...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Favorites list
          Expanded(child: _buildFavoritesList()),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Загрузка избранного...');
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadFavorites);
    }

    if (_favorites.isEmpty) {
      return const EmptyState(
        message: 'Нет избранных рецептов',
        subtitle: 'Добавьте рецепты в избранное',
        icon: Icons.favorite_border,
      );
    }

    if (_filteredFavorites.isEmpty && _searchQuery.isNotEmpty) {
      return const EmptyState(
        message: 'Ничего не найдено',
        subtitle: 'Попробуйте изменить запрос',
        icon: Icons.search_off,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredFavorites.length,
        itemBuilder: (context, index) {
          final favorite = _filteredFavorites[index];
          final recipe = favorite.recipe;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _openRecipe(favorite),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Время: ${recipe.totalTimeMinutes} мин',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteFavorite(favorite),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red.shade400,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
