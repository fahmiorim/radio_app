import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'config/app_routes.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await initializeDateFormatting('id_ID', null);
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Streaming Radio',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
