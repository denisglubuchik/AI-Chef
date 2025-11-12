import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'recipe_search_page.dart';

// Кэш для сгенерированных рецептов
final Map<String, RecipeDetail> _recipeCache = {};

class RecipeDetailPage extends StatefulWidget {
  final RecipeSuggestion suggestion;
  final RecipeDetail? cachedRecipe; // Опциональный уже готовый рецепт
  final bool? isAlreadyFavorite; // Опционально передаем статус избранного

  const RecipeDetailPage({
    super.key,
    required this.suggestion,
    this.cachedRecipe,
    this.isAlreadyFavorite,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  RecipeDetail? _recipe;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  bool _isFavorite = false;
  String? _favoriteId; // ID записи в БД для удаления
  String _loadingStatus = 'Генерируем рецепт...';

  @override
  void initState() {
    super.initState();
    // Если статус избранного передан, используем его сразу
    if (widget.isAlreadyFavorite != null) {
      _isFavorite = widget.isAlreadyFavorite!;
    }
    _loadRecipe();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      final existing = await supabase
          .from('favourite_recipes')
          .select('id')
          .eq('user_id', userId)
          .eq('title', widget.suggestion.title)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isFavorite = existing != null;
          _favoriteId = existing?['id'];
        });
      }
    } catch (e) {
      // Игнорируем ошибки проверки
    }
  }

  Future<void> _loadRecipe() async {
    // Проверяем кэш
    if (widget.cachedRecipe != null) {
      setState(() {
        _recipe = widget.cachedRecipe;
        _isLoading = false;
      });
      return;
    }

    // Проверяем глобальный кэш
    final cacheKey = widget.suggestion.suggestionId;
    if (_recipeCache.containsKey(cacheKey)) {
      setState(() {
        _recipe = _recipeCache[cacheKey];
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
      setState(() {
        _loadingStatus = 'Подбираем ингредиенты...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _loadingStatus = 'Составляем инструкции...';
      });

      // TODO: Заменить на реальный URL вашего backend
      final url = Uri.parse('http://localhost:8000/agent/build-recipe');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'suggestion_id': widget.suggestion.suggestionId,
          'title': widget.suggestion.title,
          'context_summary': widget.suggestion.description,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipe = RecipeDetail.fromJson(data);

        // Сохраняем в кэш
        _recipeCache[cacheKey] = recipe;

        setState(() {
          _recipe = recipe;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка загрузки рецепта: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка соединения: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_recipe == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      if (_isFavorite && _favoriteId != null) {
        // Удаляем из избранного
        await supabase
            .from('favourite_recipes')
            .delete()
            .eq('id', _favoriteId!);

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
        // Добавляем в избранное
        final response = await supabase
            .from('favourite_recipes')
            .insert({
              'user_id': userId,
              'title': _recipe!.title,
              'data': _recipe!.toJson(),
            })
            .select('id')
            .single();

        if (!mounted) return;

        setState(() {
          _isFavorite = true;
          _favoriteId = response['id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 8),
                Text('Рецепт добавлен в избранное'),
              ],
            ),
            backgroundColor: const Color(0xFF1B4D3E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.suggestion.title)),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    _loadingStatus,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1B4D3E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Это может занять несколько секунд',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadRecipe,
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ),
              ),
            )
          : _recipe == null
          ? const Center(child: Text('Рецепт не найден'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок и время
                  Text(
                    _recipe!.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
                        _buildInfoChip(
                          Icons.people,
                          'Порций: ${_recipe!.servings}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ингредиенты
                  const Text(
                    'Ингредиенты',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _recipe!.ingredients
                            .map(
                              (ing) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${ing.ingredient} - ${ing.quantity}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (ing.preparation != null)
                                            Text(
                                              ing.preparation!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                                fontStyle: FontStyle.italic,
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

                  // Инструменты
                  if (_recipe!.equipment.isNotEmpty) ...[
                    const Text(
                      'Необходимые инструменты',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recipe!.equipment
                          .map(
                            (eq) => Chip(
                              label: Text(eq),
                              avatar: const Icon(Icons.kitchen, size: 18),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Шаги приготовления
                  const Text(
                    'Приготовление',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._recipe!.steps.map(
                    (step) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              child: Text(
                                '${step.number}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
            ),
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

class RecipeDetail {
  final String suggestionId;
  final String title;
  final int? servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> equipment;

  RecipeDetail({
    required this.suggestionId,
    required this.title,
    this.servings,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.ingredients,
    required this.steps,
    required this.equipment,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      suggestionId: json['suggestion_id'] ?? '',
      title: json['title'] ?? 'Без названия',
      servings: json['servings'],
      prepTimeMinutes: json['prep_time_minutes'] ?? 0,
      cookTimeMinutes: json['cook_time_minutes'] ?? 0,
      ingredients:
          (json['ingredients'] as List?)
              ?.map((i) => RecipeIngredient.fromJson(i))
              .toList() ??
          [],
      steps:
          (json['steps'] as List?)
              ?.map((s) => RecipeStep.fromJson(s))
              .toList() ??
          [],
      equipment:
          (json['equipment'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggestion_id': suggestionId,
      'title': title,
      'servings': servings,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'equipment': equipment,
    };
  }
}

class RecipeIngredient {
  final String ingredient;
  final String quantity;
  final String? preparation;

  RecipeIngredient({
    required this.ingredient,
    required this.quantity,
    this.preparation,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredient: json['ingredient'] ?? '',
      quantity: json['quantity'] ?? '',
      preparation: json['preparation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient': ingredient,
      'quantity': quantity,
      'preparation': preparation,
    };
  }
}

class RecipeStep {
  final int number;
  final String instruction;
  final String? tip;

  RecipeStep({required this.number, required this.instruction, this.tip});

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      number: json['number'] ?? 0,
      instruction: json['instruction'] ?? '',
      tip: json['tip'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'number': number, 'instruction': instruction, 'tip': tip};
  }
}
