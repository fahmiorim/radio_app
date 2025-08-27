import 'package:flutter/material.dart';

// Navigation
import '../navigation/bottom_nav.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/full_player/full_player.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/artikel/artikel_detail_screen.dart';
import '../screens/program/program_detail_screen.dart';
import '../screens/galeri/album_detail_screen.dart';
import '../screens/program/all_programs_screen.dart';
import '../screens/event/all_events_screen.dart';
import '../screens/galeri/all_videos_screen.dart';

// Models
import '../models/artikel_model.dart';
import '../models/album_model.dart';
import '../models/user_model.dart';

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
  static const String albumDetail = '/album-detail';
  static const String allVideos = '/all-videos';

  // --- Static Routes (no parameter) ---
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    register: (_) => const RegisterScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    login: (_) => const LoginScreen(),
    bottomNav: (_) => const BottomNav(),
    fullPlayer: (_) => const FullPlayer(),
    allPrograms: (_) => const AllProgramsScreen(),
    allEvents: (_) => const AllEventsScreen(),
    allVideos: (_) => const AllVideosScreen(),
  };

  // --- Dynamic Routes (with parameter) ---
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case editProfile:
        final args = settings.arguments;
        if (args is Map<String, dynamic> && args['user'] is UserModel) {
          return MaterialPageRoute(
            builder: (_) => EditProfileScreen(user: args['user'] as UserModel),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('User tidak ditemukan'))),
        );

      case artikelDetail:
        final artikel = settings.arguments as Artikel;
        return MaterialPageRoute(
          builder: (_) => ArtikelDetailScreen(artikel: artikel),
        );

      case programDetail:
        final programId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ProgramDetailScreen(programId: programId),
        );

      case albumDetail:
        final slug = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AlbumDetailScreen(slug: slug),
        );
        
      case allVideos:
        return MaterialPageRoute(
          builder: (_) => const AllVideosScreen(),
        );

      default:
        return MaterialPageRoute(builder: (_) => const BottomNav());
    }
  }
}
