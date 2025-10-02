import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class EventSkeleton extends StatelessWidget {
  const EventSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // The list uses `shrinkWrap` and non-scrollable physics so it can live
    // inside another scrollable widget without causing layout issues. When
    // placing this skeleton inside a `Column` or `SliverList`, wrap it with a
    // `SizedBox` of fixed height or use `Expanded` to provide the necessary
    // vertical constraints.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16.0),
        child: EventCardSkeleton(),
      ),
    );
  }
}

class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: Card(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              AspectRatio(
                aspectRatio: 16 / 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Title placeholder
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 8),
              // Date placeholder
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
