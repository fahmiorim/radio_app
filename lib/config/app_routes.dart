import 'package:flutter/material.dart';

// Navigation
import 'package:radio_odan_app/navigation/bottom_nav.dart';

// Screens (Auth & Splash)
import 'package:radio_odan_app/screens/splash/splash_screen.dart';
import 'package:radio_odan_app/screens/auth/login_screen.dart';
import 'package:radio_odan_app/screens/auth/register_screen.dart';
import 'package:radio_odan_app/screens/auth/forgot_password_screen.dart';
import 'package:radio_odan_app/screens/auth/verification_screen.dart';
import 'package:radio_odan_app/screens/auth/reset_password_screen.dart'; // opsional

// Screens (Program)
import 'package:radio_odan_app/screens/program/program_screen.dart';
import 'package:radio_odan_app/screens/program/program_detail_screen.dart';
import 'package:radio_odan_app/screens/event/event_screen.dart';
import 'package:radio_odan_app/screens/event/event_detail_screen.dart';

// Screens (Artikel)
import 'package:radio_odan_app/screens/artikel/artikel_detail_screen.dart';
import 'package:radio_odan_app/models/artikel_model.dart';
import 'package:radio_odan_app/models/event_model.dart';

// Screens (Galeri)
import 'package:radio_odan_app/screens/galeri/album_screen.dart';
import 'package:radio_odan_app/screens/galeri/video_screen.dart';

// Screens (Profile & Player)
import 'package:radio_odan_app/screens/profile/edit_profile_screen.dart';
import 'package:radio_odan_app/screens/auth/change_password_screen.dart';
import 'package:radio_odan_app/screens/player/player_screen.dart';

// Services
import 'package:radio_odan_app/services/auth_service.dart';

// 404
import 'package:radio_odan_app/screens/common/not_found_screen.dart';

class AppRoutes {
  // --- Route Names ---
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verification = '/verification';
  static const String resetPassword = '/reset-password'; // opsional

  static const String bottomNav = '/';
  static const String fullPlayer = '/full-player';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String allVideos = '/all-videos';
  static const String artikelDetail = '/artikel-detail';
  static const String programDetail = '/program-detail';
  static const String eventDetail = '/event-detail';
  static const String allPrograms = '/program-semua';
  static const String albumList = '/album-semua';
  static const String allEvents = '/events';

  /// Hanya AUTH screens yang publik
  static List<String> get publicRoutes => [
    splash,
    login,
    register,
    forgotPassword,
    verification,
    resetPassword, // <- kalau tidak dipakai, hapus saja
  ];

  /// Semua rute lewat sini
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? bottomNav;

    // Publik → langsung build
    if (publicRoutes.contains(name)) {
      return MaterialPageRoute(
        builder: (context) => _buildRoute(settings, context),
        settings: settings,
      );
    }

    // Private → wajib login
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || snapshot.data != true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(login, (r) => false);
            });
            return const SizedBox.shrink();
          }

          return _buildRoute(settings, context);
        },
      ),
    );
  }

  /// Builder halaman aktual
  static Widget _buildRoute(RouteSettings settings, BuildContext context) {
    switch (settings.name) {
      // --- AUTH (publik)
      case splash:
        return const SplashScreen();
      case login:
        return const LoginScreen();

      case register:
        return const RegisterScreen();
      case forgotPassword:
        return const ForgotPasswordScreen();
      case verification:
        {
          final email = (settings.arguments as String?) ?? '';
          return VerificationScreen(email: email);
        }
      case resetPassword:
        {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final email = args['email']?.toString() ?? '';
          final token = args['token']?.toString();
          return ResetPasswordScreen(email: email, token: token);
        }

      // --- PRIVATE (wajib login)
      case bottomNav:
        return const BottomNav();

      case artikelDetail:
        {
          final arg = settings.arguments;
          String? slug;
          if (arg is Artikel) slug = arg.slug;
          if (arg is String) slug = arg;
          if (slug != null && slug.isNotEmpty) {
            return ArtikelDetailScreen(artikelSlug: slug);
          }
          return const NotFoundScreen();
        }

      case programDetail:
        return const ProgramDetailScreen();

      case eventDetail:
        {
          final arg = settings.arguments;
          if (arg is Event) {
            return EventDetailScreen(event: arg);
          }
          return const NotFoundScreen();
        }

      case allPrograms:
        return const AllProgramsScreen();

      case allEvents:
        return const AllEventsScreen();

      case albumList:
        return const AllAlbumsScreen();

      case fullPlayer:
        return FullPlayer();

      case editProfile:
        {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final user = args['user'];
          if (user != null) {
            return EditProfileScreen(user: user);
          }
          return const NotFoundScreen();
        }

      case changePassword:
        {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final user = args['user'];
          if (user != null) {
            return ChangePasswordScreen(user: user);
          }
          return const NotFoundScreen();
        }

      case allVideos:
        return const AllVideosScreen();

      // --- Fallback 404
      default:
        return const NotFoundScreen();
    }
  }
}
