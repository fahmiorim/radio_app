import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('404'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 100,
                color: theme.colorScheme.onBackground.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Halaman Tidak Ditemukan',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Maaf, halaman yang kamu tuju tidak tersedia atau argumennya tidak valid.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.54),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
