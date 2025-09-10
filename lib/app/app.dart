import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:radio_odan_app/config/app_theme.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/providers/auth_provider.dart';
import 'package:radio_odan_app/providers/program_provider.dart';
import 'package:radio_odan_app/providers/penyiar_provider.dart';
import 'package:radio_odan_app/providers/event_provider.dart';
import 'package:radio_odan_app/providers/artikel_provider.dart';
import 'package:radio_odan_app/providers/user_provider.dart';
import 'package:radio_odan_app/providers/video_provider.dart';
import 'package:radio_odan_app/providers/album_provider.dart';
import 'package:radio_odan_app/providers/radio_station_provider.dart';
import 'package:radio_odan_app/providers/theme_provider.dart';
import 'package:radio_odan_app/providers/live_status_provider.dart';
import 'package:radio_odan_app/services/live_chat_socket_service.dart';

import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/utils/deep_link_handler.dart';
import 'package:radio_odan_app/audio/audio_player_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class RadioApp extends StatefulWidget {
  final SharedPreferences prefs;

  const RadioApp({super.key, required this.prefs});

  @override
  State<RadioApp> createState() => _RadioAppState();
}

class _RadioAppState extends State<RadioApp> with WidgetsBindingObserver {
  late final DeepLinkHandler _deepLinkHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAppAndDeepLinks();
  }

  Future<void> _initializeAppAndDeepLinks() async {
    await initializeApp();

    // Subscribe to global live status updates
    await LiveChatSocketService.I.subscribeToStatus();

    // Initialize deep link handler
    _deepLinkHandler = DeepLinkHandler();
    _deepLinkHandler.registerHandler(
      _deepLinkHandler.handleDeepLink,
      navigatorKey,
    );

    // Initialize date formatting
    initializeDateFormatting('id_ID', null);

    // Initialize deep links after a short delay to ensure context is ready
    await Future.delayed(const Duration(milliseconds: 100));
    await _deepLinkHandler.init();

    // Check for initial deep link
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _deepLinkHandler.checkInitialLink();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkHandler.dispose();
    AudioPlayerManager.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      AudioPlayerManager.instance.stop();
    } else if (state == AppLifecycleState.resumed) {
      Provider.of<LiveStatusProvider>(context, listen: false).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(widget.prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProgramProvider()),
        ChangeNotifierProvider(create: (_) => PenyiarProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => ArtikelProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => AlbumProvider()),
        ChangeNotifierProvider(create: (_) => RadioStationProvider()),
        ChangeNotifierProvider(create: (_) => LiveStatusProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Odan FM',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

bool _isAudioInitialized = false;

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for the intl package (Indonesian locale)
  await initializeDateFormatting('id_ID', null);

  // Initialize Firebase with default settings
  await Firebase.initializeApp();

  // This will suppress the locale warnings
  await Firebase.app().setAutomaticDataCollectionEnabled(true);

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize API client with base URL from environment
  await ApiClient.I.ensureInterceptors();

  // Initialize audio service only once
  if (!_isAudioInitialized) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.odanfm.radio.channel.audio',
        androidNotificationChannelName: 'Odan FM Audio Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      );
      _isAudioInitialized = true;
    } catch (e) {
      // If already initialized, just continue
      if (!e.toString().contains('already initialized')) {
        rethrow; // Re-throw if it's a different error
      }
      _isAudioInitialized = true;
    }
  }
}
