import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../widgets/section_title.dart';
import '../../../widgets/skeleton/program_skeleton.dart';
import '../../../models/program_model.dart';
import '../../../providers/program_provider.dart';
import '../../../screens/program/all_programs_screen.dart';

class ProgramList extends StatefulWidget {
  const ProgramList({super.key});

  @override
  State<ProgramList> createState() => _ProgramListState();
}

class _ProgramListState extends State<ProgramList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ❌ tak perlu fetch di sini (sudah init di main.dart)
  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     context.read<ProgramProvider>().fetchTodaysPrograms();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final prov = context.watch<ProgramProvider>();
    final isLoading = prov.isLoadingTodays;
    final List<Program> programList = prov.todaysPrograms;
    final error = prov.todaysError;

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Gagal memuat data program. Silakan coba lagi.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final seeAll = () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AllProgramsScreen()),
      );
    };

    // Empty state (tidak ada program hari ini)
    if (programList.isEmpty && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: 'Program Hari Ini', onSeeAll: seeAll),
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
        SectionTitle(title: 'Program Hari Ini', onSeeAll: seeAll),
        const SizedBox(height: 8),
        if (isLoading)
          const ProgramSkeleton()
        else if (programList.isEmpty)
          const SizedBox.shrink()
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              key: const PageStorageKey('programs_list'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: programList.length,
              padding: const EdgeInsets.only(left: 16),
              itemBuilder: (context, index) {
                final program = programList[index];
                final url = program.gambarUrl;

                return GestureDetector(
                  onTap: () => context.read<ProgramProvider>().selectProgram(
                    program,
                    context,
                  ),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: url.isEmpty
                              ? _buildPlaceholderImage()
                              : CachedNetworkImage(
                                  imageUrl: url,
                                  height: 225,
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
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          program.penyiarName ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
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
    return SizedBox(
      height: 225,
      width: 160,
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
