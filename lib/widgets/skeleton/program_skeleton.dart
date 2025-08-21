import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProgramSkeleton extends StatelessWidget {
  final int itemCount;

  const ProgramSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
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
                  baseColor: Colors.grey[850]!, // dark mode
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    height: 225,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // shimmer judul program
                Shimmer.fromColors(
                  baseColor: Colors.grey[850]!, // dark mode
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    width: 120,
                    height: 16,
                    color: Colors.grey[850],
                  ),
                ),
                const SizedBox(height: 4),
                // shimmer nama penyiar
                Shimmer.fromColors(
                  baseColor: Colors.grey[850]!, // dark mode
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    width: 100,
                    height: 14,
                    color: Colors.grey[850],
                  ),
                ),
                const SizedBox(height: 2),
                // shimmer hari & jam
                Shimmer.fromColors(
                  baseColor: Colors.grey[850]!, // dark mode
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
