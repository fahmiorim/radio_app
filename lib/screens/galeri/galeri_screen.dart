import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/widgets/app_bar.dart';
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
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Medium bubble bottom left
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Small bubble center
                  Positioned(
                    top: 100,
                    left: 100,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
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
