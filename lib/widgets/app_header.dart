import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'skeleton/app_header_skeleton.dart';

class AppHeader extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool forceRefreshOnResume;
  final bool isLoading;

  const AppHeader({
    super.key,
    this.onMenuTap,
    this.forceRefreshOnResume = false,
    this.isLoading = false,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> with WidgetsBindingObserver {
  bool _isMounted = false;
  bool _isLoading = true;
  UserModel? _cachedUser;
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  @override
  void dispose() {
    _isMounted = false;
    _userSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.forceRefreshOnResume &&
        _isMounted) {
      _loadUserData(forceRefresh: true);
    }
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    if (!_isMounted) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();

      // Load data with cooldown check
      await userProvider.loadUser(cacheFirst: !forceRefresh);

      if (!_isMounted) return;

      // Update cached user data
      if (userProvider.user != null) {
        _cachedUser = userProvider.user;
      }
    } catch (e) {
      rethrow;
    } finally {
      if (_isMounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfileAvatar(BuildContext context, UserModel? user) {
    if (user == null) {
      return _buildInitialsAvatar('U');
    }

    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    final avatarUrl = user.avatarUrl;

    if (avatarUrl.isEmpty) {
      return _buildInitialsAvatar(initial);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildShimmerAvatar(),
          errorWidget: (context, url, error) => _buildInitialsAvatar(initial),
        ),
      ),
    );
  }

  Widget _buildShimmerAvatar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(width: 40, height: 40, color: Colors.white),
    );
  }

  Widget _buildInitialsAvatar(String initial) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const AppHeaderSkeleton();
    }

    return Selector<UserProvider, UserModel?>(
      selector: (_, provider) => provider.user,
      builder: (context, user, _) {
        // Gunakan data yang di-cache jika tersedia dan tidak ada data baru
        final displayUser = user ?? _cachedUser;

        if (_isLoading && displayUser == null) {
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
                    widget.onMenuTap ??
                    () {
                      if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                child: _buildProfileAvatar(context, displayUser),
              ),
            ],
          ),
        );
      },
    );
  }
}
