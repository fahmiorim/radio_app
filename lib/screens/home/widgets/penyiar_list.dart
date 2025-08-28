import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    // Always fetch presenters when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PenyiarProvider>(context, listen: false);
      provider.fetchPenyiars();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isLoading = context.watch<PenyiarProvider>().isLoading;
    final penyiarList = context.watch<PenyiarProvider>().penyiars;
    final error = context.watch<PenyiarProvider>().error;
    
    // Handle error
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
        SectionTitle(title: 'Penyiar'),
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
                          final penyiar = penyiarList[index];
                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Full image
                                Container(
                                  width: 110,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    image: penyiar.avatarUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              penyiar.avatarUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: penyiar.avatarUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        )
                                      : null,
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
                        },
                      )),
        ),
      ],
    );
  }
}
