import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/section_title.dart';
import '../../../widgets/skeleton/artikel_skeleton.dart';
import '../../../providers/artikel_provider.dart';
import '../../../screens/artikel/artikel_detail_screen.dart';
import '../../../navigation/bottom_nav.dart';

class ArtikelList extends StatefulWidget {
  const ArtikelList({super.key});

  @override
  State<ArtikelList> createState() => _ArtikelListState();
}

class _ArtikelListState extends State<ArtikelList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // biar state tetap hidup

  @override
  void initState() {
    super.initState();
    // Always load recent articles when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ArtikelProvider>(context, listen: false);
      provider.fetchRecentArtikels();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // WAJIB kalau pakai AutomaticKeepAliveClientMixin

    final provider = context.watch<ArtikelProvider>();
    final isLoading = provider.isLoading;
    final artikelList = provider.recentArtikels; // Use recent articles for the home screen
    final error = provider.error;

    // Handle error
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gagal memuat data artikel. Silakan coba lagi.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await context.read<ArtikelProvider>().fetchRecentArtikels();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: "Artikel",
          onSeeAll: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const BottomNav(initialIndex: 1),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        isLoading
            ? const ArtikelSkeleton()
            : SizedBox(
height: 220,
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<ArtikelProvider>().fetchRecentArtikels(),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ), // biar smooth
                    shrinkWrap: true,
                    itemCount: artikelList.length > 5 ? 5 : artikelList.length, // Show max 5 items
                    padding: const EdgeInsets.only(left: 16),
                    itemBuilder: (context, index) {
                      final artikel = artikelList[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ArtikelDetailScreen(
                                artikelSlug: artikel.slug,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  artikel.image,
                                  height: 150,
                                  width: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 80),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                artikel.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                artikel.formattedDate,
                                style: const TextStyle(
                                  fontSize: 12,
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
              ),
      ],
    );
  }
}
