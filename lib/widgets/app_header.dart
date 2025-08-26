// lib/widgets/app_header.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:radio_odan_app/services/user_service.dart';
import 'package:radio_odan_app/config/logger.dart';
import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/widgets/skeleton/app_header_skeleton.dart';

class AppHeader extends StatefulWidget {
  final bool isLoading;
  const AppHeader({super.key, this.isLoading = false});

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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/logo-white.png', height: 50),
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: _buildProfileAvatar(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    if (_user?.avatar?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: _user!.avatar!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 20,
          backgroundColor: theme.primaryColor,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: 20,
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => _buildInitialsAvatar(theme, textTheme),
      );
    }
    
    return _buildInitialsAvatar(theme, textTheme);
  }
  
  Widget _buildInitialsAvatar(ThemeData theme, TextTheme textTheme) {
    final displayName = _user?.name?.trim().isNotEmpty == true 
        ? _user!.name!.substring(0, 1).toUpperCase()
        : 'U';
    
    return CircleAvatar(
      radius: 20,
      backgroundColor: theme.primaryColor,
      child: Text(
        displayName,
        style: textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
