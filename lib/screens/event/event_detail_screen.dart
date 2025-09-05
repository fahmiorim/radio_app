import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:radio_odan_app/models/event_model.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/config/app_theme.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  Widget _buildInfoCard(String title, String value, {IconData? icon}) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Row(
                children: [
                  Icon(icon, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 8),
            value.trim().isNotEmpty
                ? Html(
                    data: value,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: AppColors.textPrimary,
                        fontSize: FontSize(14.0),
                        lineHeight: LineHeight(1.5),
                      ),
                      "p": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.only(bottom: 8.0),
                      ),
                      "a": Style(
                        color: AppColors.primary,
                        textDecoration: TextDecoration.none,
                      ),
                      "strong": Style(fontWeight: FontWeight.bold),
                      "em": Style(fontStyle: FontStyle.italic),
                    },
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _detailImage(String url) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url.isEmpty
            ? Container(
                color: const Color(0xFF1E1E1E),
                child: const Center(
                  child: Icon(
                    Icons.event_available,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF1E1E1E),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM y', 'id_ID').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar.transparent(
        title: event.judul,
        titleColor: AppColors.textPrimary,
        iconColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background gradient + bubbles
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary, AppColors.backgroundDark],
                    ),
                  ),
                  child: Stack(
                    children: [
                      AppTheme.bubble(context, size: 200, top: -50, right: -50),
                      AppTheme.bubble(
                        context,
                        size: 150,
                        bottom: -30,
                        left: -30,
                      ),
                    ],
                  ),
                ),
              ),

              // Main content
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Image
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _detailImage(event.gambar),
                          ),

                          // Status Badge
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.judul,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: event.status == 'active'
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    event.status == 'active'
                                        ? 'Aktif'
                                        : 'Tidak Aktif',
                                    style: TextStyle(
                                      color: event.status == 'active'
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Event Info Cards
                          _buildInfoCard(
                            'Waktu Acara',
                            '${_formatDate(event.tanggal)} • ${_formatTime(event.tanggal)}',
                            icon: Icons.calendar_today,
                          ),

                          if (event.penyiarName?.isNotEmpty ?? false)
                            _buildInfoCard(
                              'Penyiar',
                              event.penyiarName!,
                              icon: Icons.person,
                            ),

                          if (event.deskripsi.isNotEmpty)
                            _buildInfoCard(
                              'Deskripsi',
                              event.deskripsi,
                              icon: Icons.info_outline,
                            ),

                          const SizedBox(height: 80), // Space for mini player
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Mini Player
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MiniPlayer(),
              ),
            ],
          );
        },
      ),
    );
  }
}
