import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Config
import 'package:radio_odan_app/config/app_colors.dart';

// Providers
import 'package:radio_odan_app/providers/program_provider.dart';
import 'package:radio_odan_app/providers/event_provider.dart';
import 'package:radio_odan_app/providers/artikel_provider.dart';
import 'package:radio_odan_app/providers/penyiar_provider.dart';

// Widgets
import 'package:radio_odan_app/widgets/common/app_header.dart';
import 'package:radio_odan_app/widgets/common/app_drawer.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

// Home Widgets
import 'package:radio_odan_app/screens/home/widget/penyiar_list.dart';
import 'package:radio_odan_app/screens/home/widget/program_list.dart';
import 'package:radio_odan_app/screens/home/widget/event_list.dart';
import 'package:radio_odan_app/screens/home/widget/artikel_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool isLoading = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => isLoading = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initAll();
    });
  }

  Future<void> _initAll() async {
    final programProvider = context.read<ProgramProvider>();
    final eventProvider = context.read<EventProvider>();
    final artikelProvider = context.read<ArtikelProvider>();
    final penyiarProvider = context.read<PenyiarProvider>();

    await programProvider.init();

    await Future.wait([
      eventProvider.refresh(),
      artikelProvider.refreshRecent(),
      penyiarProvider.refresh(),
    ]);
  }

  // Auto-refresh saat app kembali dari background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshOnResume();
    }
  }

  Future<void> _refreshOnResume() async {
    final programProvider = context.read<ProgramProvider>();
    final eventProvider = context.read<EventProvider>();
    final artikelProvider = context.read<ArtikelProvider>();
    final penyiarProvider = context.read<PenyiarProvider>();

    final futures = <Future<void>>[];

    // Pakai cooldown dari provider (biar hemat request)
    if (programProvider.shouldRefreshTodayOnResume()) {
      futures.add(programProvider.refreshToday());
    }
    if (programProvider.shouldRefreshListOnResume()) {
      futures.add(programProvider.refreshList());
    }

    futures.addAll([
      eventProvider.refresh(),
      artikelProvider.refreshRecent(),
      penyiarProvider.refresh(),
    ]);

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  // Pull-to-refresh semua section di home
  Future<void> _refreshAll() async {
    final programProvider = context.read<ProgramProvider>();
    final eventProvider = context.read<EventProvider>();
    final artikelProvider = context.read<ArtikelProvider>();
    final penyiarProvider = context.read<PenyiarProvider>();

    await Future.wait([
      programProvider.refreshToday(),
      programProvider.refreshList(),
      eventProvider.refresh(),
      artikelProvider.refreshRecent(),
      penyiarProvider.refresh(),
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            key: const Key('home_stack'),
            children: [
              const AppBackground(),

              SafeArea(
                child: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refreshAll,
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
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
                          color: AppColors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 16.0,
                          ),
                          child: AppHeader(
                            key: const Key('app_header'),
                            isLoading: isLoading,
                            onMenuTap: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                        ),
                      ),

                      // Main Content
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Section: Penyiar
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: PenyiarList(),
                            ),

                            // Section: Program
                            const SizedBox(height: 32),
                            const ProgramList(),

                            // Section: Event
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: EventList(),
                            ),
                            const SizedBox(height: 24),

                            // Section: Artikel
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: ArtikelList(),
                            ),
                            const SizedBox(height: 24),
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
