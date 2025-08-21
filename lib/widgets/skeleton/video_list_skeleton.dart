import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VideoListSkeleton extends StatelessWidget {
  const VideoListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[850]!,
          highlightColor: Colors.grey[700]!,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 16, width: 200, color: Colors.grey[850]),
              ],
            ),
          ),
        );
      },
    );
  }
}
