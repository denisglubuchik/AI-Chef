import 'package:flutter/material.dart';

/// Loading indicator with optional message
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final String? subtitle;

  const LoadingIndicator({super.key, this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1B4D3E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}
