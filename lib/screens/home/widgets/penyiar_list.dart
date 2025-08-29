import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../widgets/section_title.dart';
import '../../../widgets/skeleton/penyiar_skeleton.dart';
import '../../../providers/penyiar_provider.dart';

class PenyiarList extends StatefulWidget {
  const PenyiarList({super.key});

  @override
  State<PenyiarList> createState() => _PenyiarListState();
}

class _PenyiarListState extends State<PenyiarList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ❌ Tidak perlu fetch di sini, sudah di-init di main.dart
  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     context.read<PenyiarProvider>().init();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final prov = context.watch<PenyiarProvider>();
    final isLoading = prov.isLoading;
    final penyiarList = prov.items; // ⬅️ was penyiars
    final error = prov.error;

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Gagal memuat data penyiar. Silakan coba lagi.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Penyiar'),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: isLoading
              ? const PenyiarSkeleton()
              : (penyiarList.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada data penyiar',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: penyiarList.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final p = penyiarList[index];
                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Foto penyiar
                                Container(
                                  width: 110,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                  ),
                                  child: p.avatarUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: p.avatarUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                        ),
                                ),
                                // Overlay nama
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 6,
                                  ),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Text(
                                    p.name,
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
                        },
                      )),
        ),
      ],
    );
  }
}
