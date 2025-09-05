import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radio_odan_app/config/app_colors.dart';

class NoLivePlaceholder extends StatelessWidget {
  final VoidCallback? onNotify;
  final VoidCallback? onBack;

  const NoLivePlaceholder({super.key, this.onNotify, this.onBack});

  @override
  Widget build(BuildContext context) {
    // Define gradient colors here since they can't be const
    final gradientColors = [
      AppColors().liveIndicator,
      Color.lerp(AppColors().liveIndicator, Colors.white, 0.2) ??
          AppColors().liveIndicator,
    ];
    return Container(
      color: AppColors.chatBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔴 Ikon Radio dengan efek pulse
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                onEnd: () => Future.delayed(
                  Duration.zero,
                  () => (context as Element).markNeedsBuild(),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.lightCardSurface.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors().liveIndicator.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.radio_outlined,
                    size: 64,
                    color: AppColors().liveIndicator.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Judul
              const Text(
                'Tidak Ada Siaran Saat Ini',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Siaran belum dimulai atau sedang dalam jeda.\nNantikan siaran berikutnya!',
                style: TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Tombol-tombol
              Column(
                children: [
                  // 🔔 Aktifkan Notifikasi
                  GestureDetector(
                    onTap: onNotify,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors().liveIndicator.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Aktifkan Notifikasi',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ⬅️ Kembali ke Beranda
                  GestureDetector(
                    onTap: onBack ?? () => Navigator.pop(context, 'goHome'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Kembali ke Beranda',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
