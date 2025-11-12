class RecipeSuggestion {
  final String suggestionId;
  final String title;
  final String description;
  final int? estimatedTimeMinutes;
  final double? confidence;

  RecipeSuggestion({
    required this.suggestionId,
    required this.title,
    required this.description,
    this.estimatedTimeMinutes,
    this.confidence,
  });

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) {
    return RecipeSuggestion(
      suggestionId: json['suggestion_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Без названия',
      description: json['short_description'] as String? ?? '',
      estimatedTimeMinutes: json['estimated_time_minutes'] as int?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggestion_id': suggestionId,
      'title': title,
      'short_description': description,
      if (estimatedTimeMinutes != null)
        'estimated_time_minutes': estimatedTimeMinutes,
      if (confidence != null) 'confidence': confidence,
    };
  }
}
