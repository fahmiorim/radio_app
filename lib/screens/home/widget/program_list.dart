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

class _ProgramListState extends State<ProgramList>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

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
    super.build(context);

    final prov = context.watch<ProgramProvider>();
    final bool isLoading = prov.isLoadingTodays;
    final List<ProgramModel> programList = prov.todaysPrograms;
    final String? error = prov.todaysError;

    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Program Hari Ini',
            onSeeAll: () => _openAll(context),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Gagal memuat data program. Silakan tarik untuk refresh.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    if (programList.isEmpty && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Program Hari Ini',
            onSeeAll: () => _openAll(context),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Tidak ada program untuk hari ini',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Program Hari Ini',
          onSeeAll: () => _openAll(context),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const ProgramSkeleton()
        else if (programList.isEmpty)
          const SizedBox.shrink()
        else
          SizedBox(
            height: 260,
            child: ListView.builder(
              key: const PageStorageKey('programs_list'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: programList.length,
              padding: const EdgeInsets.only(left: 12),
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
                              ? _buildPlaceholderImage()
                              : CachedNetworkImage(
                                  imageUrl: url,
                                  height: 200,
                                  width: 160,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _buildLoadingThumb(),
                                  errorWidget: (_, __, ___) =>
                                      _buildPlaceholderImage(),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          program.namaProgram,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 225,
      width: 160,
      color: Colors.grey[900],
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 44, color: Colors.white38),
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
