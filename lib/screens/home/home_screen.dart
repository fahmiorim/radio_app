import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Config
import 'package:radio_odan_app/config/app_colors.dart';

// Providers
import '../../providers/program_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/artikel_provider.dart';
import '../../providers/penyiar_provider.dart';

// Widgets
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';

// Home Widgets
import 'widgets/penyiar_list.dart';
import 'widgets/program_list.dart';
import 'widgets/event_list.dart';
import 'widgets/artikel_list.dart';

// Refresh indicator key for the home screen

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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Refresh all list widgets
  Future<void> _refreshAll() async {
    try {
      final programProvider = Provider.of<ProgramProvider>(
        context,
        listen: false,
      );
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final artikelProvider = Provider.of<ArtikelProvider>(
        context,
        listen: false,
      );
      final penyiarProvider = Provider.of<PenyiarProvider>(
        context,
        listen: false,
      );

      // Force refresh all providers in parallel using their specific refresh methods
      await Future.wait([
        programProvider.refreshAll(),
        eventProvider.refresh(),
        artikelProvider.fetchRecentArtikels(),
        penyiarProvider.refresh(),
      ]);
    } catch (e) {
      debugPrint('Error during refresh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
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
                child: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refreshAll,
                  color: AppColors.primary,
                  backgroundColor: AppColors.backgroundDark,
                  child: CustomScrollView(
                    key: const Key('home_scroll_view'),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
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
                                Scaffold.of(
                                  _scaffoldKey.currentContext!,
                                ).openDrawer();
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
                            // List widgets
                            const PenyiarList(),
                            const SizedBox(height: 16),
                            const ProgramList(),
                            const SizedBox(height: 8),
                            const EventList(),
                            const SizedBox(height: 8),
                            const ArtikelList(),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
