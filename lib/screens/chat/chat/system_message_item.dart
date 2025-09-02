import 'package:flutter/material.dart';

class SystemMessageItem extends StatelessWidget {
  final String message;
  const SystemMessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
