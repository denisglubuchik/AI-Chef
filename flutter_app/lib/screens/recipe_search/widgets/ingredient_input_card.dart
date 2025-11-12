import 'package:flutter/material.dart';

/// Card for ingredient input
class IngredientInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const IngredientInputCard({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Ингредиенты',
        hintText: 'Например: курица, рис, морковь',
        helperText: 'Введите вручную или загрузите фото',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }
}
