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
      ingredient: json['ingredient'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      preparation: json['preparation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient': ingredient,
      'quantity': quantity,
      if (preparation != null) 'preparation': preparation,
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
      number: json['number'] as int? ?? 0,
      instruction: json['instruction'] as String? ?? '',
      tip: json['tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'instruction': instruction,
      if (tip != null) 'tip': tip,
    };
  }
}

class Recipe {
  final String suggestionId;
  final String title;
  final int? servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> equipment;

  Recipe({
    required this.suggestionId,
    required this.title,
    this.servings,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.ingredients,
    required this.steps,
    List<String>? equipment,
  }) : equipment = equipment ?? [];

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      suggestionId: json['suggestion_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Без названия',
      servings: json['servings'] as int?,
      prepTimeMinutes: json['prep_time_minutes'] as int? ?? 0,
      cookTimeMinutes: json['cook_time_minutes'] as int? ?? 0,
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map(
                (item) =>
                    RecipeIngredient.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((item) => RecipeStep.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      equipment:
          (json['equipment'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggestion_id': suggestionId,
      'title': title,
      if (servings != null) 'servings': servings,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'equipment': equipment,
    };
  }
}
