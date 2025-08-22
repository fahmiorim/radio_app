import 'package:flutter/material.dart';
import '../../data/dummy_artikel.dart';
import '../../models/artikel_model.dart';
import '../details/artikel_detail_screen.dart';
import '../../widgets/skeleton/artikel_all_skeleton.dart';

class ArtikelScreen extends StatefulWidget {
  const ArtikelScreen({super.key});

  @override
  State<ArtikelScreen> createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulasi delay loading
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Artikel"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const ArtikelAllSkeleton()
          : ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 160,
                left: 16,
                right: 16,
                top: 16,
              ),
              // itemCount: dummyArtikel.length,
              itemBuilder: (context, index) {
                // final Artikel artikel = dummyArtikel[index];
                return GestureDetector(
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) =>
                    //         ArtikelDetailScreen(artikel: artikel),
                    //   ),
                    // );
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                        ), // jarak atas-bawah item
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Optimasi: cacheWidth biar gambar gak decode full-res
                            // ClipRRect(
                            //   borderRadius: BorderRadius.circular(8),
                            //   child: Image.asset(
                            //     artikel.imageUrl,
                            //     width: 80,
                            //     height: 80,
                            //     fit: BoxFit.cover,
                            //     cacheWidth: 200,
                            //   ),
                            // ),
                            const SizedBox(width: 12),
                            // Info artikel
                            // Expanded(
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       Text(
                            //         artikel.title,
                            //         maxLines: 2,
                            //         overflow: TextOverflow.ellipsis,
                            //         style: const TextStyle(
                            //           fontSize: 16,
                            //           fontWeight: FontWeight.bold,
                            //         ),
                            //       ),
                            //       const SizedBox(height: 6),

                            //       const SizedBox(height: 4),
                            //       Text(
                            //         artikel.date,
                            //         style: const TextStyle(
                            //           fontSize: 12,
                            //           color: Colors.grey,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      // Garis bawah dengan jarak
                      const Divider(
                        color: Color.fromARGB(255, 48, 48, 48),
                        height: 5,
                        thickness: 0.5,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
