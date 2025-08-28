import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/logger.dart';
import '../../config/app_routes.dart';
import 'login_screen.dart';
import 'verification_screen.dart';
import '../../services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();

      if (mounted) {
        setState(() {
          _isAuthenticated = isLoggedIn;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error checking auth status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If user is authenticated, show the app
    if (_isAuthenticated) {
      return WillPopScope(
        onWillPop: () async {
          // Show exit confirmation if on home screen
          if (ModalRoute.of(context)?.settings.name == AppRoutes.bottomNav) {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Keluar Aplikasi'),
                content: const Text('Apakah Anda yakin ingin keluar?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Tidak'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Ya'),
                  ),
                ],
              ),
            );
            return shouldPop ?? false;
          }
          return true;
        },
        child: widget.child,
      );
    }

    // If not authenticated, handle public routes
    return WillPopScope(
      onWillPop: () async {
        // Allow back button on login/register/verification screens
        return true;
      },
      child: Navigator(
        onGenerateRoute: (settings) {
          // Check if the route is public
          if (AppRoutes.publicRoutes.contains(settings.name)) {
            // Handle verification route with email parameter
            if (settings.name == AppRoutes.verification) {
              final email = settings.arguments as String? ?? '';
              return MaterialPageRoute(
                builder: (context) => VerificationScreen(email: email),
                settings: settings,
              );
            }

            // Default to login screen for other public routes
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
              settings: settings,
            );
          }

          // Redirect to login for any other route
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        },
      ),
    );
  }
}
