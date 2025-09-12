import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/providers/theme_provider.dart';

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Switch.adaptive(
      value: themeProvider.isDarkMode,
      onChanged: (value) {
        themeProvider.toggleTheme(value);
      },
      activeColor: Theme.of(context).colorScheme.secondary,
    );
  }
}
