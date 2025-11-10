import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'recipe_detail_page.dart';
import 'routes.dart';

class RecipeSearchPage extends StatefulWidget {
  const RecipeSearchPage({super.key});

  @override
  State<RecipeSearchPage> createState() => _RecipeSearchPageState();
}

class _RecipeSearchPageState extends State<RecipeSearchPage> {
  final TextEditingController _ingredientsController = TextEditingController();
  List<RecipeSuggestion> _recipes = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _searchRecipes() async {
    final ingredientsText = _ingredientsController.text.trim();

    if (ingredientsText.isEmpty) {
      setState(() {
        _errorMessage = 'Введите хотя бы один ингредиент';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _recipes = [];
    });

    try {
      // Разделяем ингредиенты по запятым
      final ingredients = ingredientsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // TODO: Заменить на реальный URL вашего backend
      final url = Uri.parse('http://localhost:8000/agent/suggest-meals');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ingredients': ingredients}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dishes = data['dishes'] as List;

        setState(() {
          _recipes = dishes.map((s) => RecipeSuggestion.fromJson(s)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка: ${response.statusCode}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск рецептов'),
        actions: [
          IconButton(
            tooltip: 'Открыть профиль',
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed(Routes.profile);
            },
          ),
        ],
      ),
      body: _buildRecipeSearchView(),
    );
  }

  Widget _buildRecipeSearchView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ingredientsController,
            decoration: const InputDecoration(
              labelText: 'Ингредиенты',
              hintText: 'Например: курица, рис, морковь',
              helperText: 'Введите ингредиенты через запятую',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _searchRecipes,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Найти рецепты'),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          if (_recipes.isNotEmpty) ...[
            const Text(
              'Найденные рецепты:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: _recipes.isEmpty && !_isLoading
                ? const Center(
                    child: Text(
                      'Введите ингредиенты и нажмите "Найти рецепты"',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailPage(suggestion: recipe),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                const SizedBox(height: 8),
                                Text(
                                  recipe.description,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class RecipeSuggestion {
  final String suggestionId;
  final String title;
  final String description;

  RecipeSuggestion({
    required this.suggestionId,
    required this.title,
    required this.description,
  });

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) {
    return RecipeSuggestion(
      suggestionId: json['suggestion_id'] ?? '',
      title: json['title'] ?? 'Без названия',
      description: json['short_description'] ?? '',
    );
  }
}
