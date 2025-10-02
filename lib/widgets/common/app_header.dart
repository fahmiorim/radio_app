import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

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
      await userProvider.loadUser(cacheFirst: !forceRefresh);

      if (!_isMounted) return;
      if (userProvider.user != null) {
        _cachedUser = userProvider.user;
      }
    } catch (_) {
      rethrow;
    } finally {
      if (_isMounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfileAvatar(BuildContext context, UserModel? user) {
    if (user == null) return _buildShimmerAvatar();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final avatarUrl = user.avatarUrl.isNotEmpty ? user.avatarUrl : null;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

    if (avatarUrl == null) {
      return _buildInitialsAvatar(initial);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildShimmerAvatar(),
          errorWidget: (context, url, error) => _buildInitialsAvatar(initial),
        ),
      ),
    );
  }

  Widget _buildShimmerAvatar() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInitialsAvatar(String initial) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || _isLoading) {
      return const AppHeaderSkeleton();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Selector<UserProvider, UserModel?>(
      selector: (_, provider) => provider.user,
      builder: (context, user, _) {
        final displayUser = user ?? _cachedUser;

        if (_isLoading && displayUser == null) {
          return const AppHeaderSkeleton();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border(
              bottom: BorderSide(
                color: colors.outline.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo + App name
              Row(
                children: [
                  // Logo mark
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/logo.png', height: 30),
                  ),
                  const SizedBox(width: 12),

                  // App Name: "ODAN" gradient text + "FM" solid
                  Text(
                    'ODAN',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontFamily: 'Poppins',
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: colors.shadow.withValues(alpha: 0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'FM',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),

              // Avatar / Menu
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
