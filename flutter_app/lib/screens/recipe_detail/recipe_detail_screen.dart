import 'package:flutter/material.dart';

import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/error_view.dart';
import '../../models/recipe.dart';
import '../../models/suggestion.dart';
import '../../services/recipe_service.dart';
import '../../services/favorites_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeSuggestion suggestion;
  final Recipe? cachedRecipe;

  const RecipeDetailScreen({
    super.key,
    required this.suggestion,
    this.cachedRecipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  final FavoritesService _favoritesService = FavoritesService();

  Recipe? _recipe;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFavorite = false;
  String? _favoriteId;
  String? _errorMessage;
  String _loadingStatus = 'Генерируем рецепт...';

  @override
  void initState() {
    super.initState();
    _loadRecipe();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFav = await _favoritesService.isFavorite(widget.suggestion.title);
      final favId = await _favoritesService.getFavoriteId(
        widget.suggestion.title,
      );

      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _favoriteId = favId;
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _loadRecipe() async {
    if (widget.cachedRecipe != null) {
      setState(() {
        _recipe = widget.cachedRecipe;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingStatus = 'Генерируем рецепт...';
    });

    try {
      // Simulate progress updates
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _loadingStatus = 'Подбираем ингредиенты...');
      }

      final recipe = await _recipeService.buildRecipe(
        suggestionId: widget.suggestion.suggestionId,
        title: widget.suggestion.title,
        contextSummary: widget.suggestion.description,
      );

      if (!mounted) return;

      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_recipe == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      if (_isFavorite && _favoriteId != null) {
        await _favoritesService.removeFavoriteById(_favoriteId!);

        if (!mounted) return;

        setState(() {
          _isFavorite = false;
          _favoriteId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite_border, color: Colors.white),
                SizedBox(width: 8),
                Text('Рецепт удален из избранного'),
              ],
            ),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final favId = await _favoritesService.addFavorite(_recipe!);

        if (!mounted) return;

        setState(() {
          _isFavorite = true;
          _favoriteId = favId;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 8),
                Text('Рецепт добавлен в избранное'),
              ],
            ),
            backgroundColor: Color(0xFF1B4D3E),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.suggestion.title)),
      body: _buildBody(),
      floatingActionButton: _recipe != null
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _toggleFavorite,
              backgroundColor: _isFavorite
                  ? Colors.red.shade400
                  : const Color(0xFF1B4D3E),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              label: Text(
                _isSaving
                    ? 'Сохранение...'
                    : _isFavorite
                    ? 'Удалить из избранного'
                    : 'В избранное',
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingIndicator(
        message: _loadingStatus,
        subtitle: 'Это может занять несколько секунд',
      );
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadRecipe);
    }

    if (_recipe == null) {
      return const ErrorView(message: 'Рецепт не найден');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and time info
          Text(
            _recipe!.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              _buildInfoChip(
                Icons.timer,
                'Подготовка: ${_recipe!.prepTimeMinutes} мин',
              ),
              _buildInfoChip(
                Icons.local_fire_department,
                'Готовка: ${_recipe!.cookTimeMinutes} мин',
              ),
              if (_recipe!.servings != null)
                _buildInfoChip(Icons.people, 'Порций: ${_recipe!.servings}'),
            ],
          ),
          const SizedBox(height: 24),

          // Ingredients
          const Text(
            'Ингредиенты',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _recipe!.ingredients
                    .map(
                      (ing) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2.0),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ing.ingredient} - ${ing.quantity}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (ing.preparation != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        ing.preparation!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Equipment
          if (_recipe!.equipment.isNotEmpty) ...[
            const Text(
              'Необходимые инструменты',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recipe!.equipment
                  .asMap()
                  .entries
                  .map(
                    (entry) => Chip(
                      label: Text(entry.value),
                      avatar: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _getEquipmentColors(entry.key),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      backgroundColor: Colors.grey.shade50,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Steps
          const Text(
            'Приготовление',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._recipe!.steps.map(
            (step) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      child: Text(
                        '${step.number}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.instruction,
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (step.tip != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 16,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      step.tip!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.amber.shade900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
    );
  }

  List<Color> _getEquipmentColors(int index) {
    // Палитра в стиле приложения - зеленые и теплые оттенки
    final colorPairs = [
      [const Color(0xFF1B4D3E), const Color(0xFF2D7A5F)], // Темно-зеленый
      [const Color(0xFF3A8F6B), const Color(0xFF4CAF7D)], // Средне-зеленый
      [const Color(0xFFFF9800), const Color(0xFFFFB74D)], // Оранжевый
      [const Color(0xFF5C6BC0), const Color(0xFF7986CB)], // Синий
      [const Color(0xFF26A69A), const Color(0xFF4DB6AC)], // Бирюзовый
      [const Color(0xFFEF5350), const Color(0xFFE57373)], // Красный
      [const Color(0xFFAB47BC), const Color(0xFFBA68C8)], // Фиолетовый
    ];

    return colorPairs[index % colorPairs.length];
  }
}
