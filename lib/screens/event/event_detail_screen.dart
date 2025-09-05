import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:radio_odan_app/models/event_model.dart';
import 'package:radio_odan_app/config/app_theme.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/widgets/app_bar.dart';
import 'package:radio_odan_app/widgets/mini_player.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  Widget _thumbPlaceholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
        ),
      );

  Widget _thumbLoading() => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final url = event.gambarUrl;

    return Scaffold(
      appBar: CustomAppBar.transparent(title: event.judul),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Background gradient with bubbles
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.background,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  AppTheme.bubble(
                    context,
                    size: 200,
                    top: 50,
                    right: -50,
                  ),
                  AppTheme.bubble(
                    context,
                    size: 250,
                    bottom: -50,
                    left: -50,
                    opacity: AppColors.bubbleDefaultOpacity * 0.6,
                  ),
                ],
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: url.isEmpty
                        ? _thumbPlaceholder(context)
                        : CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _thumbLoading(),
                            errorWidget: (_, __, ___) =>
                                _thumbPlaceholder(context),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  event.judul,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.user ?? '-',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.formattedTanggal,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  event.deskripsi,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}

