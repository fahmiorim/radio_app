import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/services/auth_service.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Tunggu minimal 1 detik untuk splash screen
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    // Periksa status login
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // Jika sudah login, arahkan ke bottom navigation
      Navigator.pushReplacementNamed(context, AppRoutes.bottomNav);
    } else {
      // Jika belum login, arahkan ke halaman login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoPath = theme.brightness == Brightness.dark
        ? 'assets/logo.png'
        : 'assets/logo.png';

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                logoPath,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
