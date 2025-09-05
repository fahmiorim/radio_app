import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/config/app_theme.dart';
import 'package:radio_odan_app/providers/album_provider.dart';
import 'package:radio_odan_app/providers/video_provider.dart';
import 'widget/video_list.dart';
import 'widget/album_list.dart';

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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar.transparent(title: 'Galeri'),
      body: Stack(
        children: [
          // Background with gradient and bubbles
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.backgroundDark],
                ),
              ),
              child: Stack(
                children: [
                  // Large bubble top right
                  AppTheme.bubble(
                    context,
                    size: 200,
                    top: -50,
                    right: -50,
                  ),
                  // Medium bubble bottom left
                  AppTheme.bubble(
                    context,
                    size: 150,
                    bottom: -30,
                    left: -30,
                  ),
                  // Small bubble center
                  AppTheme.bubble(
                    context,
                    size: 50,
                    top: 100,
                    left: 100,
                    opacity: 0.05,
                  ),
                ],
              ),
            ),
          ),
          // Main Content with RefreshIndicator
          SafeArea(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const VideoList(),
                        const SizedBox(height: 1),
                        const AlbumList(),
                        const SizedBox(height: 8), // Reduced space
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
