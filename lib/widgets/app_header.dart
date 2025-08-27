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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await UserService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            Colors.blueAccent.withOpacity(0.15),
            Colors.purpleAccent.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Branding
          Row(
            children: [
              Image.asset('assets/logo-white.png', height: 40),
              const SizedBox(width: 12),
              const Text(
                "ODAN FM",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
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

    if (_user?.avatar?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: _user!.avatar!,
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
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: const CircleAvatar(radius: 22, backgroundColor: Colors.grey),
    );
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    final displayName = _user?.name?.trim().isNotEmpty == true
        ? _user!.name![0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.blueAccent,
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
