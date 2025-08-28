import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool get isLoading => context.watch<ProgramProvider>().isLoadingTodays;
  List<Program> get programList => context.watch<ProgramProvider>().todaysPrograms;

  @override
  void initState() {
    super.initState();
    // Fetch program only once when first initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProgramProvider>();
      if (provider.todaysPrograms.isEmpty) {
        provider.fetchTodaysPrograms();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // WAJIB kalau pakai AutomaticKeepAlive

    // Handle error
    final error = context.select<ProgramProvider, String?>((p) => p.todaysError);
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

    // Show empty state if no programs for today
    if (programList.isEmpty && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: "Program Hari Ini",
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllProgramsScreen(),
                ),
              );
            },
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
          title: "Program Hari Ini",
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllProgramsScreen(),
              ),
            );
          },
        ),
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

                    return GestureDetector(
                      onTap: () {
                        final provider = context.read<ProgramProvider>();
                        provider.selectProgram(program, context);
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: program.gambar.isNotEmpty
                                  ? Image.network(
                                      program.gambarUrl,
                                      height: 225,
                                      width: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildPlaceholderImage(),
                                    )
                                  : _buildPlaceholderImage(),
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
                              program.penyiarName ?? "-",
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
      color: Colors.grey[300],
      child: const Icon(Icons.image, size: 50),
    );
  }

  @override
  bool get wantKeepAlive => true; // ✅ biar state tetap hidup
}
