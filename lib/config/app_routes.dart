import 'package:flutter/material.dart';

// Navigation
import '../navigation/bottom_nav.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/full_player/full_player.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';

import '../screens/details/artikel_detail_screen.dart';
import '../screens/program/program_detail_screen.dart';
import '../screens/details/event_detail_screen.dart';
import '../screens/details/album_detail_screen.dart';
import '../screens/program/all_programs_screen.dart';

// Models
import '../models/artikel_model.dart';
import '../models/program_model.dart';
import '../models/event_model.dart';
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
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String artikelDetail = '/artikel-detail';
  static const String programDetail = '/program-detail';
  static const String allPrograms = '/program-semua';
  static const String eventDetail = '/event-detail';
  static const String albumDetail = '/album-detail';

  // --- Static Routes (no parameter) ---
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    register: (_) => const RegisterScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    login: (_) => const LoginScreen(),
    profile: (_) => const ProfileScreen(),
    bottomNav: (_) => const BottomNav(),
    fullPlayer: (_) => const FullPlayer(),
    allPrograms: (_) => const AllProgramsScreen(),
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

      case eventDetail:
        final event = settings.arguments as Event;
        return MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: event),
        );

      case albumDetail:
        final album = settings.arguments as AlbumModel;
        return MaterialPageRoute(
          builder: (_) => AlbumDetailScreen(album: album),
        );

      default:
        return MaterialPageRoute(builder: (_) => const BottomNav());
    }
  }
}
