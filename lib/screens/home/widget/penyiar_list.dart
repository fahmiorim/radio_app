import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:radio_odan_app/models/penyiar_model.dart';
import 'package:radio_odan_app/providers/penyiar_provider.dart';
import 'package:radio_odan_app/widgets/common/section_title.dart';
import 'package:radio_odan_app/widgets/skeleton/penyiar_skeleton.dart';

class PenyiarList extends StatefulWidget {
  const PenyiarList({super.key});

  @override
  State<PenyiarList> createState() => _PenyiarListState();
}

class _PenyiarListState extends State<PenyiarList>
    with WidgetsBindingObserver {

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
                  ? Center(
                      child: Text(
                        'Tidak ada data penyiar',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
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
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat data penyiar',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
    final theme = Theme.of(context);
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
            color: theme.colorScheme.surface,
            child: penyiar.avatarUrl.isEmpty
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: theme.colorScheme.onSurface.withOpacity(0.38),
                  )
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
                    errorWidget: (_, __, ___) => Icon(
                      Icons.person,
                      size: 50,
                      color: theme.colorScheme.onSurface.withOpacity(0.38),
                    ),
                  ),
          ),
          // Nama overlay
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.5),
            child: Text(
              penyiar.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
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
