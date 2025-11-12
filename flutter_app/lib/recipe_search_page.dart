import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'recipe_detail_page.dart';
import 'routes.dart';

class RecipeSearchPage extends StatefulWidget {
  const RecipeSearchPage({super.key});

  @override
  State<RecipeSearchPage> createState() => _RecipeSearchPageState();
}

class _RecipeSearchPageState extends State<RecipeSearchPage> {
  final TextEditingController _ingredientsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<RecipeSuggestion> _recipes = [];
  bool _isLoading = false;
  bool _isExtracting = false;
  String? _errorMessage;
  XFile? _selectedImage;

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
        // Пытаемся получить детали ошибки из ответа
        String errorDetail = 'Ошибка ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['detail'] != null) {
            errorDetail = errorData['detail'].toString();
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            errorDetail = response.body;
          }
        }

        setState(() {
          _errorMessage = errorDetail;
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
        // Автоматически распознаем ингредиенты
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
      // TODO: Заменить на реальный URL вашего backend
      final url = Uri.parse('http://localhost:8000/agent/extract-ingredients');

      // Читаем байты изображения для поддержки веб-платформы
      final bytes = await _selectedImage!.readAsBytes();

      // Определяем MIME-тип по расширению файла
      String mimeType = 'image/jpeg'; // По умолчанию
      final fileName = _selectedImage!.name.toLowerCase();
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      var request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _selectedImage!.name,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ingredients = (data['ingredients'] as List)
            .map((i) => i['name'].toString())
            .toList();

        setState(() {
          // Добавляем найденные ингредиенты в текстовое поле
          _ingredientsController.text = ingredients.join(', ');
          _isExtracting = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Найдено ${ingredients.length} ингредиентов'),
            backgroundColor: const Color(0xFF1B4D3E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Пытаемся получить детали ошибки из ответа
        String errorDetail = 'Ошибка ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['detail'] != null) {
            errorDetail = errorData['detail'].toString();
          }
        } catch (_) {
          // Если не удалось распарсить, показываем raw body
          if (response.body.isNotEmpty) {
            errorDetail = response.body;
          }
        }

        setState(() {
          _errorMessage = 'Ошибка распознавания: $errorDetail';
          _isExtracting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка соединения: $e';
        _isExtracting = false;
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
          // Кнопка загрузки фото
          OutlinedButton.icon(
            onPressed: _isExtracting ? null : _showImageSourceDialog,
            icon: const Icon(Icons.add_a_photo),
            label: Text(
              _selectedImage == null
                  ? 'Загрузить фото продуктов'
                  : 'Изменить фото',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFF1B4D3E)),
              foregroundColor: const Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 16),

          // Превью фото
          if (_selectedImage != null) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B4D3E), width: 2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FutureBuilder<Uint8List>(
                      future: _selectedImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          );
                        }
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isExtracting)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 12),
                              Text(
                                'Распознаем ингредиенты...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 4,
                      child: IconButton(
                        onPressed: _isExtracting
                            ? null
                            : () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                        icon: const Icon(Icons.close, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _ingredientsController,
            decoration: const InputDecoration(
              labelText: 'Ингредиенты',
              hintText: 'Например: курица, рис, морковь',
              helperText: 'Введите вручную или загрузите фото',
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
