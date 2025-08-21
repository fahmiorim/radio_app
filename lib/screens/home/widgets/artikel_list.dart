import 'package:flutter/material.dart';
import '../../../widgets/section_title.dart';
import '../../../data/dummy_artikel.dart';
import '../../../widgets/skeleton/artikel_skeleton.dart';
import '../../../config/app_routes.dart';

class ArtikelList extends StatefulWidget {
  const ArtikelList({super.key});

  @override
  State<ArtikelList> createState() => _ArtikelListState();
}

class _ArtikelListState extends State<ArtikelList>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true; // biar state tetap hidup

  @override
  void initState() {
    super.initState();
    // tampilkan skeleton 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // WAJIB kalau pakai AutomaticKeepAliveClientMixin
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: "Artikel"),
        const SizedBox(height: 8),
        isLoading
            ? const ArtikelSkeleton()
            : SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(), // biar smooth
                  shrinkWrap: true,
                  itemCount: dummyArtikel.length,
                  padding: const EdgeInsets.only(left: 16),
                  itemBuilder: (context, index) {
                    final artikel = dummyArtikel[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.artikelDetail,
                          arguments: artikel,
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
                              child: Image.asset(
                                artikel.imageUrl,
                                height: 150,
                                width: 160,
                                fit: BoxFit.cover,
                                // optimasi biar gambar ga berat
                                cacheWidth: 320,
                                cacheHeight: 300,
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
                              ),
                            ),
                            Text(
                              artikel.date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
}
