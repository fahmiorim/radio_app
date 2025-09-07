import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/providers/user_provider.dart';
import 'package:radio_odan_app/widgets/skeleton/app_header_skeleton.dart';

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
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          width: 1.5,
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceVariant,
      highlightColor: colorScheme.surface,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initial) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
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
            color: Theme.of(context).colorScheme.surface,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceVariant,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.2),
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
                  Image.asset('assets/logo.png', height: 40),
                  const SizedBox(width: 12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'ODAN',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                fontFamily: 'Poppins',
                                shadows: [
                                  Shadow(
                                    color: Theme.of(
                                      context,
                                    ).shadowColor.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                        ),
                        TextSpan(
                          text: ' FM',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
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
