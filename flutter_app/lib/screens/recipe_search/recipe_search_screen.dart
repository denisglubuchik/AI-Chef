import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/suggestion.dart';
import '../../services/recipe_service.dart';
import '../../routes.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import 'widgets/ingredient_input_card.dart';
import 'widgets/image_preview_card.dart';
import 'widgets/suggestion_list.dart';

class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  final TextEditingController _ingredientsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final RecipeService _recipeService = RecipeService();

  List<RecipeSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _isExtracting = false;
  String? _errorMessage;
  XFile? _selectedImage;

  @override
  void dispose() {
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: AppConstants.maxImageWidth.toDouble(),
        maxHeight: AppConstants.maxImageHeight.toDouble(),
        imageQuality: AppConstants.imageQuality.toInt(),
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
        await _extractIngredients();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при выборе изображения: $e';
      });
    }
  }

  Future<void> _extractIngredients() async {
    if (_selectedImage == null) return;

    setState(() {
      _isExtracting = true;
      _errorMessage = null;
    });

    try {
      final result = await _recipeService.extractIngredients(_selectedImage!);

      if (!mounted) return;

      setState(() {
        _ingredientsController.text = result.ingredients
            .map((i) => i.name)
            .join(', ');
        _isExtracting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Найдено ${result.ingredients.length} ингредиентов'),
          backgroundColor: const Color(0xFF1B4D3E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Ошибка распознавания: $e';
        _isExtracting = false;
      });
    }
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
      _suggestions = [];
    });

    try {
      final ingredients = ingredientsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final suggestions = await _recipeService.getSuggestions(
        ingredients: ingredients,
      );

      if (!mounted) return;

      setState(() {
        _suggestions = suggestions;
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

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите источник'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSuggestionTap(RecipeSuggestion suggestion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(suggestion: suggestion),
      ),
    );
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image picker and preview
          ImagePreviewCard(
            selectedImage: _selectedImage,
            isExtracting: _isExtracting,
            onPickImage: _showImageSourceDialog,
            onRemoveImage: () => setState(() => _selectedImage = null),
          ),

          const SizedBox(height: 16),

          // Ingredients input
          IngredientInputCard(
            controller: _ingredientsController,
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          // Search button
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

          // Error message
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

          const SizedBox(height: 12),

          // Suggestions list
          Expanded(child: _buildSuggestionsList()),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoading) {
      return const LoadingIndicator(
        message: 'Ищем рецепты...',
        subtitle: 'Это может занять несколько секунд',
      );
    }

    if (_suggestions.isEmpty) {
      return const EmptyState(
        message: 'Введите ингредиенты и нажмите "Найти рецепты"',
        icon: Icons.search,
      );
    }

    return SuggestionList(
      suggestions: _suggestions,
      onTap: _handleSuggestionTap,
    );
  }
}
