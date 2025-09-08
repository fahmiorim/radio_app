import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:radio_odan_app/widgets/common/section_title.dart';
import 'package:radio_odan_app/widgets/skeleton/artikel_skeleton.dart';
import 'package:radio_odan_app/models/artikel_model.dart';
import 'package:radio_odan_app/providers/artikel_provider.dart';
import 'package:radio_odan_app/screens/artikel/artikel_screen.dart';
import 'package:radio_odan_app/screens/artikel/artikel_detail_screen.dart';

class ArtikelList extends StatefulWidget {
  const ArtikelList({super.key});

  @override
  State<ArtikelList> createState() => ArtikelListState();
}

class ArtikelListState extends State<ArtikelList>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<ArtikelProvider>();
      if (prov.recentArtikels.isEmpty) {
        await prov.loadRecent(cacheFirst: true);
      } else if (prov.shouldRefreshOnResume()) {
        await prov.refreshRecent();
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
      final prov = context.read<ArtikelProvider>();
      if (prov.shouldRefreshOnResume()) {
        prov.refreshRecent();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ArtikelProvider>();
    final bool isLoading = prov.isLoadingRecent;
    final List<Artikel> artikelList = prov.recentArtikels;
    final String? error = prov.recentError;

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

    // Empty state (tidak ada program hari ini)
    if (artikelList.isEmpty && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Artikel Terbaru',
            onSeeAll: () => _openAll(context),
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada artikel tersedia',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        SectionTitle(
          title: 'Artikel Terbaru',
          onSeeAll: () => _openAll(context),
        ),
        if (isLoading)
          const ArtikelSkeleton()
        else if (artikelList.isEmpty)
          const SizedBox.shrink()
        else
          GridView.builder(
            key: const PageStorageKey('artikel_list'),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: artikelList.length > 4 ? 4 : artikelList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final artikel = artikelList[index];
              final url = artikel.gambarUrl;

              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtikelDetailScreen(
                        artikelSlug: artikel.slug,
                      ),
                    ),
                  );
                  if (mounted) {}
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: url.isEmpty
                            ? _buildPlaceholderImage()
                            : CachedNetworkImage(
                                imageUrl: url,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    _buildLoadingThumb(),
                                errorWidget: (context, url, error) =>
                                    _buildPlaceholderImage(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artikel.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artikel.publishedAt != null
                          ? DateFormat(
                              'dd MMM yyyy',
                            ).format(artikel.publishedAt!)
                          : '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _openAll(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ArtikelScreen()),
    );
  }

  Widget _buildPlaceholderImage() {
    final theme = Theme.of(context);
    return Container(
      height: 225,
      width: 160,
      color: theme.colorScheme.surface,
      alignment: Alignment.center,
      child: Icon(
        Icons.image,
        size: 44,
        color: theme.colorScheme.onSurface.withOpacity(0.38),
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
