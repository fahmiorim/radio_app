import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:radio_odan_app/widgets/common/section_title.dart';
import 'package:radio_odan_app/widgets/skeleton/program_skeleton.dart';
import 'package:radio_odan_app/models/program_model.dart';
import 'package:radio_odan_app/providers/program_provider.dart';
import 'package:radio_odan_app/screens/program/program_screen.dart';
import 'package:radio_odan_app/screens/program/program_detail_screen.dart';

class ProgramList extends StatefulWidget {
  const ProgramList({super.key});

  @override
  State<ProgramList> createState() => _ProgramListState();
}

class _ProgramListState extends State<ProgramList> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<ProgramProvider>();
      if (prov.todaysPrograms.isEmpty) {
        await prov.loadToday(cacheFirst: true);
      } else if (prov.shouldRefreshTodayOnResume()) {
        await prov.refreshToday();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final prov = context.read<ProgramProvider>();
      if (prov.shouldRefreshTodayOnResume()) {
        prov.refreshToday();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProgramProvider>();
    final bool isLoading = prov.isLoadingTodays;
    final List<ProgramModel> programList = prov.todaysPrograms;
    final String? error = prov.todaysError;

    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Program Hari Ini'),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat data program',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan tarik untuk refresh',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (programList.isEmpty && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Program Hari Ini'),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.schedule,
                  size: 40,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tidak ada program untuk hari ini',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Program Hari Ini',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _openAll(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lihat Semua',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (isLoading)
          const ProgramSkeleton()
        else if (programList.isEmpty)
          const SizedBox.shrink()
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            height: 260,
            child: ListView.builder(
              key: const PageStorageKey('programs_list'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: programList.length,
              itemBuilder: (context, index) {
                final program = programList[index];
                final url = program.gambarUrl;

                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProgramDetailScreen(),
                        settings: RouteSettings(arguments: program.id),
                      ),
                    );
                    if (mounted) {}
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: url.isEmpty
                              ? _buildPlaceholderImage(context)
                              : CachedNetworkImage(
                                  imageUrl: url,
                                  height: 200,
                                  width: 160,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => _buildLoadingThumb(),
                                  errorWidget: (_, _, _) =>
                                      _buildPlaceholderImage(context),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          program.namaProgram,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openAll(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AllProgramsScreen()),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      height: 225,
      width: 160,
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.center,
      child: Icon(
        Icons.image,
        size: 44,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
      ),
    );
  }

  Widget _buildLoadingThumb() {
    return const SizedBox(
      height: 225,
      width: 160,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
