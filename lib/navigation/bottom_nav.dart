import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/artikel/artikel_screen.dart';
import '../screens/galeri/galeri_screen.dart';
import '../screens/chat/live_chat_screen.dart';
import '../widgets/mini_player.dart';
import '../widgets/app_drawer.dart';

class BottomNav extends StatefulWidget {
  final int initialIndex;
  
  const BottomNav({super.key, this.initialIndex = 0});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    ArtikelScreen(),
    GaleriScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Drawer
      drawer: const AppDrawer(), // ⬅️ panggil widget app_drawer
      extendBody: true,
      body: Stack(
        children: [
          _screens[_currentIndex],

          /// Gradient bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height:
                  kBottomNavigationBarHeight +
                  90 +
                  MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          /// MiniPlayer
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).padding.bottom +
                    kBottomNavigationBarHeight +
                    6,
              ),
              child: const MiniPlayer(),
            ),
          ),
        ],
      ),

      /// BottomNav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        onTap: (index) async {
          if (index == 3) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveChatScreen()),
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
    );
  }
}
