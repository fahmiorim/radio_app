import 'package:flutter/material.dart';

// Config
import 'package:radio_odan_app/config/app_colors.dart';

// Widgets
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';

// Home Widgets
import 'widgets/penyiar_list.dart';
import 'widgets/program_list.dart';
import 'widgets/event_list.dart';
import 'widgets/artikel_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        key: const Key('play_button'),
        onPressed: () {
          // TODO: Implement play/pause
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.music_note, color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            key: const Key('home_stack'),
            children: [
              // Background with gradient and bubbles
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary, AppColors.backgroundDark],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Large bubble top right
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Medium bubble bottom left
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Small bubble center
                      Positioned(
                        top: 100,
                        left: 100,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Main Content
              SafeArea(
                child: CustomScrollView(
                  key: const Key('home_scroll_view'),
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: AppHeader(
                          key: const Key('app_header'),
                          isLoading: isLoading,
                          onMenuTap: () {
                            if (_scaffoldKey.currentContext != null) {
                              Scaffold.of(_scaffoldKey.currentContext!).openDrawer();
                            }
                          },
                        ),
                      ),
                    ),
                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(key: Key('top_padding'), height: 4),
                          const PenyiarList(key: Key('penyiar_list')),
                          const SizedBox(height: 16),
                          const ProgramList(key: Key('program_list')),
                          const SizedBox(height: 8),
                          const EventList(key: Key('event_list')),
                          const SizedBox(height: 8),
                          const ArtikelList(key: Key('artikel_list')),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
