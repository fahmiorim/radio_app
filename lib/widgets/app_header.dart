import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:radio_odan_app/services/user_service.dart';
import 'package:radio_odan_app/config/logger.dart';
import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/widgets/skeleton/app_header_skeleton.dart';

class AppHeader extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onMenuTap;

  const AppHeader({super.key, this.isLoading = false, this.onMenuTap});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadUserProfile();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!_isMounted) return;

    try {
      final user = await UserService.getProfile(forceRefresh: false);
      if (!_isMounted) return;
      
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!_isMounted) return;
      logger.e('Error loading user profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || _isLoading) {
      return const AppHeaderSkeleton();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 2, 45, 155),
            const Color.fromARGB(255, 2, 42, 128),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Branding
          Row(
            children: [
              Image.asset('assets/logo-white.png', height: 40),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'ODAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontFamily: 'Poppins',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: ' FM',
                      style: TextStyle(
                        color: Colors.amber[300],
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontFamily: 'Poppins',
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Avatar User
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap:
                widget.onMenuTap ??
                () {
                  if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
                    Scaffold.of(context).openDrawer();
                  }
                },
            child: _buildProfileAvatar(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final theme = Theme.of(context);

    final avatarUrl = _user?.avatar;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: CircleAvatar(radius: 20, backgroundImage: imageProvider),
        ),
        placeholder: (context, url) => _buildShimmerAvatar(),
        errorWidget: (context, url, error) => _buildInitialsAvatar(theme),
      );
    }

    return _buildInitialsAvatar(theme);
  }

  Widget _buildShimmerAvatar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[700]!,
      child: const CircleAvatar(radius: 22, backgroundColor: Colors.grey),
    );
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    final name = _user?.name;
    final displayName = (name != null && name.trim().isNotEmpty)
        ? name[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.blueGrey[800],
      child: Text(
        displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
