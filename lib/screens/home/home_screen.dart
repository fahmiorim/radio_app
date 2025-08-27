import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import '../home/widgets/penyiar_list.dart';
import '../home/widgets/program_list.dart';
import '../home/widgets/event_list.dart';
import '../home/widgets/artikel_list.dart';
import '../../config/app_colors.dart';

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
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: AppHeader(
                  isLoading: isLoading,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // The `SizedBox` widgets here are intentionally non-const
                  // because using the same const instance multiple times in a
                  // `SliverChildListDelegate` can cause layout issues.
                  SizedBox(height: 8),
                  const PenyiarList(),
                  SizedBox(height: 24),
                  const ProgramList(),
                  SizedBox(height: 24),
                  const EventList(),
                  SizedBox(height: 24),
                  const ArtikelList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
