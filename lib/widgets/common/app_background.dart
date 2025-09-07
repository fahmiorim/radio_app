import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary,
              colorScheme.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            AppTheme.bubble(
              context: context,
              size: 200,
              top: -50,
              right: -50,
            ),
            AppTheme.bubble(
              context: context,
              size: 150,
              bottom: -30,
              left: -30,
              usePrimaryColor: false,
            ),
            AppTheme.bubble(
              context: context,
              size: 50,
              top: 100,
              left: 100,
              usePrimaryColor: false,
              opacity: 0.05,
            ),
          ],
        ),
      ),
    );
  }
}

