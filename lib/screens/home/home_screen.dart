import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
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
                child: AppHeader(isLoading: isLoading),
              ),
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  const PenyiarList(),
                  const SizedBox(height: 24),
                  const ProgramList(),
                  const SizedBox(height: 24),
                  const EventList(),
                  const SizedBox(height: 24),
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
