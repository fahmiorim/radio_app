import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/providers/album_provider.dart';
import 'package:radio_odan_app/providers/video_provider.dart';
import 'widget/video_list.dart';
import 'widget/album_list.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

class GaleriScreen extends StatefulWidget {
  const GaleriScreen({super.key});

  @override
  State<GaleriScreen> createState() => _GaleriScreenState();
}

class _GaleriScreenState extends State<GaleriScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> _handleRefresh() async {
    try {
      // Refresh both providers in parallel
      await Future.wait([
        Provider.of<VideoProvider>(
          context,
          listen: false,
        ).fetchRecentVideos(forceRefresh: true),
        Provider.of<AlbumProvider>(
          context,
          listen: false,
        ).fetchFeaturedAlbums(forceRefresh: true),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    // Trigger initial refresh after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'Galeri'),
      body: Stack(
        children: [
          const AppBackground(),
          // Main Content with RefreshIndicator
          SafeArea(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              color: colors.primary,
              backgroundColor: colors.surface,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const VideoList(),
                        const SizedBox(height: 16),
                        const AlbumList(),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
