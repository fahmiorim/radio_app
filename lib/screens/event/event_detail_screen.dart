import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:radio_odan_app/models/event_model.dart';
import 'package:radio_odan_app/config/app_theme.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  Widget _buildInfoCard(String title, String value, {IconData? icon}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        
        return Card(
          color: colors.surface,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colors.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null)
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
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
                            color: colors.onSurfaceVariant,
                            fontSize: FontSize(14.0),
                            lineHeight: LineHeight(1.5),
                          ),
                          "p": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.only(bottom: 8.0),
                          ),
                          "a": Style(
                            color: colors.primary,
                            textDecoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
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
      },
    );
  }

  Widget _detailImage(String url) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: url.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.event_available,
                        size: 80,
                        color: colors.onSurfaceVariant.withOpacity(0.5),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: colors.primary,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colors.error,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gagal memuat gambar',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          );
        },
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
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: CustomAppBar.transparent(
        context: context,
        title: event.judul,
        titleColor: colors.onBackground,
        iconColor: colors.onBackground,
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
                  color: colors.background,
                  child: Stack(
                    children: [
                      AppTheme.bubble(
                        context: context,
                        size: 200,
                        top: -50,
                        right: -50,
                        opacity: isDarkMode ? 0.1 : 0.03,
                        usePrimaryColor: true,
                      ),
                      AppTheme.bubble(
                        context: context,
                        size: 150,
                        bottom: -30,
                        left: -30,
                        opacity: isDarkMode ? 0.15 : 0.04,
                        usePrimaryColor: true,
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
                                  child: Builder(
                                    builder: (context) => Text(
                                      event.judul,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: event.status == 'active'
                                        ? colors.tertiaryContainer
                                        : colors.errorContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    event.status == 'active' ? 'Aktif' : 'Tidak Aktif',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: event.status == 'active'
                                          ? colors.onTertiaryContainer
                                          : colors.onErrorContainer,
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
