import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'skeleton/app_header_skeleton.dart';

class AppHeader extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onMenuTap;

  const AppHeader({super.key, this.isLoading = false, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (isLoading || userProvider.isLoading) {
      return const AppHeaderSkeleton();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 2, 45, 155),
            Color.fromARGB(255, 2, 42, 128),
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap:
                onMenuTap ??
                () {
                  if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
                    Scaffold.of(context).openDrawer();
                  }
                },
            child: _buildProfileAvatar(context, user),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, UserModel? user) {
    final theme = Theme.of(context);
    final url = user?.avatarUrl ?? ''; // <- gunakan getter dari model

    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: CircleAvatar(radius: 20, backgroundImage: imageProvider),
        ),
        placeholder: (_, __) => _buildShimmerAvatar(),
        errorWidget: (_, __, error) {
          // log error kalau perlu
          // debugPrint('Error loading avatar: $error');
          return _buildInitialsAvatar(theme, user);
        },
      );
    }

    return _buildInitialsAvatar(theme, user);
  }

  Widget _buildShimmerAvatar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[700]!,
      child: const CircleAvatar(radius: 22, backgroundColor: Colors.grey),
    );
  }

  Widget _buildInitialsAvatar(ThemeData theme, UserModel? user) {
    final initial = (user != null && user.name.trim().isNotEmpty)
        ? user.name[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.blueGrey[800],
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
