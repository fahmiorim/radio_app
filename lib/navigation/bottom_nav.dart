import 'package:flutter/material.dart';
import 'package:radio_odan_app/screens/home/home_screen.dart';
import 'chat_screen_wrapper.dart';
import 'package:radio_odan_app/screens/galeri/galeri_screen.dart';
import 'package:radio_odan_app/screens/artikel/artikel_screen.dart';
import 'package:radio_odan_app/services/live_chat_service.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/common/app_drawer.dart';

class BottomNav extends StatefulWidget {
  final int initialIndex;

  const BottomNav({super.key, this.initialIndex = 0});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late int _currentIndex;

  int? _roomId;
  bool _isLoadingRoom = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchLiveStatus();
  }

  Future<void> _fetchLiveStatus() async {
    try {
      final status = await LiveChatService.I.fetchGlobalStatus();
      if (mounted) {
        setState(() {
          _roomId = status.roomId;
          _isLoadingRoom = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoom = false);
      }
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const ArtikelScreen(),
    const GaleriScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Drawer
      drawer: const AppDrawer(), // ⬅️ panggil widget app_drawer
      extendBody: true,
      body: Stack(
        children: [
          // Main Content
          _screens[_currentIndex],

          // MiniPlayer with Gradient Background
          Positioned(
            left: 0,
            right: 0,
            bottom: kBottomNavigationBarHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.onSurface,
                    Theme.of(context).colorScheme.background,
                  ],
                ),
              ),
              child: const MiniPlayer(),
            ),
          ),
        ],
      ),

      /// BottomNav
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
            elevation: 8,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) async {
              if (index == 3) {
                if (_isLoadingRoom) {
                  // Tampilkan loading indicator jika masih memuat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Memuat ruang chat...')),
                  );
                  return;
                }

                if (_roomId == null) {
                  // Tampilkan pesan error jika tidak ada room yang aktif
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak ada siaran aktif saat ini')),
                    );
                  }
                  return;
                }

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreenWrapper(roomId: _roomId!),
                  ),
                );

                if (result == 'goHome') {
                  setState(() {
                    _currentIndex = 0;
                  });
                }
              } else {
                setState(() {
                  _currentIndex = index;
                });
              }
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
      ),
    );
  }
}
