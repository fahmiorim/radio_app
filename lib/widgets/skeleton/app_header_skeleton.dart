import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppHeaderSkeleton extends StatelessWidget {
  const AppHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Konsisten ukuran dengan AppHeader
    const outerRadius = 20.0;
    const horizontalPad = 24.0;
    const verticalPad = 16.0;

    // Ukuran elemen kiri (logo tile + icon kira-kira 40x40 total)
    const logoTileSize = 40.0;
    const logoCorner = 12.0;

    // Perkiraan tinggi teks dari headlineSmall
    final headlineSize = (theme.textTheme.headlineSmall?.fontSize ?? 24.0);
    final odanHeight = (headlineSize * 1.10).clamp(22.0, 36.0);
    final fmHeight = (headlineSize * 0.80).clamp(18.0, 30.0);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(outerRadius),
          bottomRight: Radius.circular(outerRadius),
        ),
        border: Border(
          bottom: BorderSide(color: colors.outline.withOpacity(0.08), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      // Clip konten agar shimmer nggak keluar radius → menghindari artefak tepi (kesan double)
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(outerRadius),
          bottomRight: Radius.circular(outerRadius),
        ),
        child: Shimmer.fromColors(
          baseColor: colors.surfaceVariant,
          highlightColor: colors.surface,
          period: const Duration(milliseconds: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kiri: tile logo + “ODAN” + “FM”
              Row(
                children: [
                  // SINGLE BOX: tile logo (tanpa inner box)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(logoCorner),
                    child: Container(
                      width: logoTileSize,
                      height: logoTileSize,
                      color: colors.surfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Placeholder teks “ODAN” + “FM”
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // “ODAN”
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 90,
                          height: odanHeight,
                          color: colors.onSurface.withOpacity(0.10),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // “FM”
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 36,
                          height: fmHeight,
                          color: colors.onSurface.withOpacity(0.10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Kanan: SINGLE CIRCLE avatar (tanpa ring ganda)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.onSurface.withOpacity(0.10),
                  shape: BoxShape.circle,
                  // Shadow ringan biar tetap “naik” tapi tidak kelihatan cincin kedua
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
