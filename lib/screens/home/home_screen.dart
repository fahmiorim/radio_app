import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../home/widgets/penyiar_list.dart';
import '../home/widgets/program_list.dart';
import '../home/widgets/event_list.dart';
import '../home/widgets/artikel_list.dart';

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
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          title: AppHeader(
            isLoading: isLoading,
          ), // ⬅️ skeleton atau header asli
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: PenyiarList()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: ProgramList()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: EventList()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: ArtikelList()),
        // Padding tambahan supaya tidak menempel ke MiniPlayer / BottomNav
        SliverPadding(padding: const EdgeInsets.only(bottom: 170)),
      ],
    );
  }
}
