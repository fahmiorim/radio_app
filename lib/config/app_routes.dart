import 'package:flutter/material.dart';
import 'package:radio_odan_app/screens/auth/register_screen.dart';
import 'package:radio_odan_app/screens/auth/verification_screen.dart';
import 'package:radio_odan_app/services/auth_service.dart';

// Navigation
import '../navigation/bottom_nav.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/program/all_programs_screen.dart';
import '../screens/program/program_detail_screen.dart';
import '../screens/artikel/artikel_detail_screen.dart';
import '../screens/galeri/all_videos_screen.dart';
import '../screens/galeri/all_albums_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../models/artikel_model.dart';

class AppRoutes {
  // --- Route Names ---
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String bottomNav = '/';
  static const String fullPlayer = '/full-player';
  static const String editProfile = '/edit-profile';
  static const String artikelDetail = '/artikel-detail';
  static const String programDetail = '/program-detail';
  static const String allPrograms = '/program-semua';
  static const String allEvents = '/event-semua';
  static const String albumList = '/album-semua';
  static const String allVideos = '/all-videos';
  static const String albumDetail = '/album-detail';
  static const String verification = '/verification';

  // List of public routes that don't require authentication
  static List<String> get publicRoutes => [
        splash,
        login,
        register,
        forgotPassword,
        bottomNav,
        artikelDetail,
        programDetail,
        allPrograms,
        allEvents,
        allVideos,
      ];

  // --- Static Routes (no parameter) ---
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    bottomNav: (_) => const BottomNav(),
    allPrograms: (_) => const AllProgramsScreen(),
    allVideos: (_) => const AllVideosScreen(),
    albumList: (_) => const AllAlbumsScreen(),
    verification: (context) {
      final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
      return VerificationScreen(email: email);
    },
  };

  // Check if a route requires authentication
  static bool requiresAuth(String? routeName) {
    if (routeName == null) return true;
    return !publicRoutes.contains(routeName);
  }

  // --- Dynamic Routes (with parameter) ---
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle verification route separately - no auth check needed
    if (settings.name == verification) {
      return MaterialPageRoute(
        builder: (context) => _buildRoute(settings, context),
        settings: settings,
      );
    }

    // For other public routes
    if (!requiresAuth(settings.name)) {
      return MaterialPageRoute(
        builder: (context) => _buildRoute(settings, context),
        settings: settings,
      );
    }

    // For protected routes, check authentication
    return MaterialPageRoute(
      builder: (context) => FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data != true) {
            // Redirect to login if not authenticated
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushNamedAndRemoveUntil(login, (route) => false);
            });
            return const SizedBox.shrink();
          }

          // Continue with the requested route if authenticated
          return _buildRoute(settings, context);
        },
      ),
    );
  }

  static Widget _buildRoute(RouteSettings settings, BuildContext context) {
    switch (settings.name) {
      case bottomNav:
        return const BottomNav();
      case login:
        return const LoginScreen();
      case register:
        return const RegisterScreen();
      case forgotPassword:
        return const ForgotPasswordScreen();
      case verification:
        final email = settings.arguments as String? ?? '';
        return VerificationScreen(email: email);
      case splash:
        return const SplashScreen();
      case programDetail:
        // The ProgramProvider will handle the selected program state
        return const ProgramDetailScreen();
      case artikelDetail:
        final artikel = settings.arguments as Artikel?;
        if (artikel != null) {
          return ArtikelDetailScreen(artikelSlug: artikel.slug);
        }
        return const BottomNav();
      case allVideos:
        return const AllVideosScreen();
      case albumList:
        return const AllAlbumsScreen();
      case editProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        final user = args?['user'];
        if (user != null) {
          return EditProfileScreen(user: user);
        }
        return const BottomNav();
      default:
        // If route is not found, go to home
        return const BottomNav();
    }
  }
}
