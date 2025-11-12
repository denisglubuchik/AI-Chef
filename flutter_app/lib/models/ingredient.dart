class DetectedIngredient {
  final String name;
  final double confidence;
  final String? notes;

  DetectedIngredient({
    required this.name,
    required this.confidence,
    this.notes,
  });

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    return DetectedIngredient(
      name: json['name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Result from ingredient extraction
class IngredientExtractionResult {
  final List<DetectedIngredient> ingredients;
  final List<String> unsureItems;
  final List<String> spoiledItems;

  IngredientExtractionResult({
    required this.ingredients,
    List<String>? unsureItems,
    List<String>? spoiledItems,
  }) : unsureItems = unsureItems ?? [],
       spoiledItems = spoiledItems ?? [];

  factory IngredientExtractionResult.fromJson(Map<String, dynamic> json) {
    return IngredientExtractionResult(
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map(
                (item) =>
                    DetectedIngredient.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      unsureItems:
          (json['unsure_items'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      spoiledItems:
          (json['spoiled_items'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
    );
  }
}
