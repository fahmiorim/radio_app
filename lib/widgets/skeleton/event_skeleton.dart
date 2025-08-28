import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_colors.dart';

class EventSkeleton extends StatelessWidget {
  const EventSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // The list is wrapped with `shrinkWrap` and non-scrollable physics so it can
    // live inside another scrollable widget without causing layout issues. Make
    // sure that a surrounding widget (e.g. a `Column` or `SizedBox`) provides
    // adequate height if further scrolling is required.
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
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Card(
        color: AppColors.surface.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              AspectRatio(
                aspectRatio: 16/9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Title placeholder
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 8),
              // Date placeholder
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white24,
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
