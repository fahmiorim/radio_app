import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppHeaderSkeleton extends StatelessWidget {
  const AppHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 2, 45, 155),
            Color.fromARGB(255, 2, 42, 128),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[700]!,
        highlightColor: Colors.grey[600]!,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo + Text
            Row(
              children: [
                // Logo placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                // ODAN FM text placeholder
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'ODAN FM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontFamily: 'Poppins',
                      backgroundColor: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
            // Avatar placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
