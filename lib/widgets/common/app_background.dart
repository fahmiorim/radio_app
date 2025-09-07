import 'package:flutter/material.dart';

/// A simple background widget that fills the available space
/// with the application's background color.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
    );
  }
}
