import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/program_provider.dart';
import 'providers/penyiar_provider.dart';
import 'providers/event_provider.dart';
import 'providers/artikel_provider.dart';
import 'providers/user_provider.dart';
import 'providers/video_provider.dart';
import 'providers/album_provider.dart';
import 'providers/radio_station_provider.dart';

import 'config/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with default settings
  await Firebase.initializeApp();

  // This will suppress the locale warnings
  await Firebase.app().setAutomaticDataCollectionEnabled(true);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Setup API client interceptors (auth header, cookies, csrf, etc)
  ApiClient.I.ensureInterceptors();

  // Locale for dates
  await initializeDateFormatting('id_ID', null);

  // Background audio channel
  await JustAudioBackground.init(
    androidNotificationChannelId: 'id.go.batubarakab.odanfm.channel.audio',
    androidNotificationChannelName: 'Odan FM Playback',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // Singleton managers live across app lifecycle; nothing to dispose here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final p = AuthProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = UserProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = PenyiarProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = ProgramProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = EventProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = ArtikelProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = VideoProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = AlbumProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(create: (_) => RadioStationProvider()),
      ],
      child: MaterialApp(
        title: 'Radio Odan 89.3 FM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,

        // Semua rute melewati satu gerbang (onGenerateRoute) → aman dari bypass auth
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
