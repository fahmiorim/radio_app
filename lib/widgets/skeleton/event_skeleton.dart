import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class EventSkeleton extends StatelessWidget {
  final int itemCount;

  const EventSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // penting
        shrinkWrap: true, // penting
        padding: const EdgeInsets.only(left: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // shimmer gambar
                Shimmer.fromColors(
                  baseColor: Colors.grey[850]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    height: 220,
                    width: 200,
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
                    width: 150,
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
                    width: 100,
                    height: 14,
                    color: Colors.grey[850],
                  ),
                ),
                const SizedBox(height: 2),
                // shimmer waktu
                Shimmer.fromColors(
                  baseColor: Colors.grey[850]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    width: 60,
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
