import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AllProgramsSkeleton extends StatelessWidget {
  final int itemCount;

  const AllProgramsSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                baseColor: theme.colorScheme.surfaceVariant,
                highlightColor: theme.colorScheme.surface,
                child: Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
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
                      baseColor: theme.colorScheme.surfaceVariant,
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: theme.colorScheme.surfaceVariant,
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Shimmer.fromColors(
                      baseColor: theme.colorScheme.surfaceVariant,
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
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
