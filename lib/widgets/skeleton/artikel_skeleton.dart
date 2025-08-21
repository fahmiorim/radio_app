import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ArtikelSkeleton extends StatelessWidget {
  final int itemCount;

  const ArtikelSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // shimmer gambar
                Shimmer.fromColors(
                  baseColor: Colors.grey[850]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    height: 150,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // shimmer judul
                Shimmer.fromColors(
                  baseColor: Colors.grey[850]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    width: 120,
                    height: 16,
                    color: Colors.grey[850],
                  ),
                ),
                const SizedBox(height: 4),
                // shimmer tanggal
                Shimmer.fromColors(
                  baseColor: Colors.grey[850]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    width: 80,
                    height: 12,
                    color: Colors.grey[850],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
