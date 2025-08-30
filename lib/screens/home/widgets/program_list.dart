import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';

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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  bool _isMounted = false;
  List<Program>? _lastItems;

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    WidgetsBinding.instance.addObserver(this);

    // Load data setelah frame pertama supaya aman dari context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    await context.read<ProgramProvider>().fetchTodaysPrograms(
      forceRefresh: forceRefresh,
    );
    if (mounted) {
      setState(() {
        _lastItems = List<Program>.from(
          context.read<ProgramProvider>().todaysPrograms,
        );
      });
    }
  }

  // Public method: bisa dipanggil parent untuk hard refresh
  Future<void> refreshData() async {
    await _loadData(forceRefresh: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndRefresh();
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final provider = context.read<ProgramProvider>();
    final currentItems = provider.todaysPrograms;
    final shouldRefresh = _lastItems == null ||
        !const DeepCollectionEquality().equals(_lastItems, currentItems);

    if (shouldRefresh) {
      await provider.fetchTodaysPrograms(forceRefresh: true);
      if (mounted) {
        setState(() {
          _lastItems = List<Program>.from(provider.todaysPrograms);
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isMounted) {
      _checkAndRefresh();
    }
  }

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
