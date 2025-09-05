import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll; // opsional, kalau mau ada tombol "Lihat Semua"
  final TextStyle? titleStyle;

  const SectionTitle({
    super.key,
    required this.title,
    this.onSeeAll,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style:
                titleStyle ??
                const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  letterSpacing: 0.5,
                ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                "Lihat Semua",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.amber300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
