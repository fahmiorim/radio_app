import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/screens/home/home_screen.dart';
import 'chat_screen_wrapper.dart';
import 'package:radio_odan_app/screens/galeri/galeri_screen.dart';
import 'package:radio_odan_app/screens/artikel/artikel_screen.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/common/app_drawer.dart';
import 'package:radio_odan_app/providers/live_status_provider.dart';

class BottomNav extends StatefulWidget {
  final int initialIndex;
  const BottomNav({super.key, this.initialIndex = 0});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    ArtikelScreen(),
    GaleriScreen(),
    SizedBox.shrink(), // placeholder utk tab Chat (biar aman)
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      // extendBody: true, // Hapus extendBody untuk mencegah bottomNavigationBar menutupi MiniPlayer
      body: (_currentIndex < _screens.length)
          ? _screens[_currentIndex]
          : _screens[0],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // MiniPlayer with Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.onSurface,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: const MiniPlayer(),
            ),
            // Bottom Navigation Bar
            Theme(
              data: Theme.of(context).copyWith(
                bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  selectedItemColor: Theme.of(context).primaryColor,
                  unselectedItemColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                  elevation: 8,
                  type: BottomNavigationBarType.fixed,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) async {
                  if (index == 3) {
                    // opsional: sync status terkini
                    await context.read<LiveStatusProvider>().refresh();
                    await Navigator.of(context).push(ChatScreenWrapper.route());
                    return; // jangan ubah _currentIndex
                  }
                  setState(() => _currentIndex = index);
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.article_outlined),
                    label: "Artikel",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.photo_library_outlined),
                    label: "Galeri",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline),
                    label: "Chat",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
