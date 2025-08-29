import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'audio/audio_player_manager.dart';
import 'screens/auth/auth_wrapper.dart';
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

  await dotenv.load(fileName: '.env');

  ApiClient.I.ensureInterceptors();

  await initializeDateFormatting('id_ID', null);
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioPlayerManager().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final manager = AudioPlayerManager();
    if (state == AppLifecycleState.paused) {
      _wasPlaying = manager.player.playing;
      manager.pause();
    } else if (state == AppLifecycleState.resumed && _wasPlaying) {
      manager.player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        builder: (context, child) => AuthWrapper(child: child!),
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
