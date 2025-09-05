import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_colors.dart';

class PenyiarSkeleton extends StatelessWidget {
  final int itemCount;

  const PenyiarSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Shimmer.fromColors(
                  baseColor: AppColors.grey850,
                  highlightColor: AppColors.grey700,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.grey850,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Shimmer.fromColors(
                  baseColor: AppColors.grey850,
                  highlightColor: AppColors.grey700,
                  child: Container(
                    width: 60,
                    height: 14,
                    color: AppColors.grey850,
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
