import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../models/penyiar_model.dart';
import '../../../../providers/penyiar_provider.dart';
import '../../../../widgets/section_title.dart';
import '../../../../widgets/skeleton/penyiar_skeleton.dart';

class PenyiarList extends StatefulWidget {
  const PenyiarList({super.key});

  @override
  State<PenyiarList> createState() => _PenyiarListState();
}

class _PenyiarListState extends State<PenyiarList>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // init setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenyiarProvider>().init();
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
      final prov = context.read<PenyiarProvider>();
      if (prov.shouldRefreshOnResume(const Duration(seconds: 45))) {
        prov.refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Selector<PenyiarProvider, _PenyiarVm>(
      selector: (_, p) => _PenyiarVm(
        isLoading: p.isLoading,
        items: List<Penyiar>.from(p.items),
        error: p.error,
      ),
      builder: (context, vm, _) {
        if (vm.error != null && vm.items.isEmpty) {
          return _errorView(
            onRetry: () => context.read<PenyiarProvider>().refresh(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Penyiar Radio'),
            SizedBox(
              height: 160,
              child: vm.isLoading && vm.items.isEmpty
                  ? const PenyiarSkeleton()
                  : vm.items.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada data penyiar',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: vm.items.length,
                      itemBuilder: (context, index) {
                        final p = vm.items[index];
                        return _PenyiarCard(penyiar: p);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _errorView({required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data penyiar',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _PenyiarCard extends StatelessWidget {
  final Penyiar penyiar;
  const _PenyiarCard({required this.penyiar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Foto
          Container(
            width: 110,
            height: 160,
            color: Colors.grey[900],
            child: penyiar.avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : CachedNetworkImage(
                    imageUrl: penyiar.avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
          ),
          // Nama overlay
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            color: Colors.black.withOpacity(0.5),
            child: Text(
              penyiar.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PenyiarVm {
  final bool isLoading;
  final List<Penyiar> items;
  final String? error;
  const _PenyiarVm({
    required this.isLoading,
    required this.items,
    required this.error,
  });
}
