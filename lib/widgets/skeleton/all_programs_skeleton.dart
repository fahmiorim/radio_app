import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_colors.dart';

class AllProgramsSkeleton extends StatelessWidget {
  final int itemCount;

  const AllProgramsSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Shimmer.fromColors(
                baseColor: AppColors.grey850,
                highlightColor: AppColors.grey700,
                child: Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.grey850,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: AppColors.grey850,
                      highlightColor: AppColors.grey700,
                      child: Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.grey850,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: AppColors.grey850,
                      highlightColor: AppColors.grey700,
                      child: Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.grey850,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Shimmer.fromColors(
                      baseColor: AppColors.grey850,
                      highlightColor: AppColors.grey700,
                      child: Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.grey850,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
