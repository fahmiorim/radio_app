import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AlbumListSkeleton extends StatelessWidget {
  const AlbumListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceVariant, // dark theme base
          highlightColor: theme.colorScheme.surface, // shimmer highlight
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
