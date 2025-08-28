import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:radio_odan_app/services/user_service.dart';
import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/config/logger.dart';
import 'package:radio_odan_app/config/app_routes.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
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
      logger.e('Error loading user profile in drawer: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToEditProfile() {
    final currentUser = _user;
    if (currentUser != null) {
      Navigator.pop(context);
      Navigator.pushNamed(
        context,
        '/edit-profile',
        arguments: {'user': currentUser},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width * 0.82,
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.primaryColor, theme.scaffoldBackgroundColor],
            ),
          ),
          child: Stack(
            children: [
              // Bubble Effects
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
              // Main Content
              SafeArea(
                child: Column(
                  children: [
                    // HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor.withOpacity(0.9),
                            theme.primaryColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildProfileAvatar(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.name ?? 'Nama Pengguna',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _user?.email ?? 'email@example.com',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // MENU LIST
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              children: [
                                _buildMenuItem(
                                  icon: Icons.edit,
                                  title: "Edit Profile",
                                  onTap: _navigateToEditProfile,
                                ),
                                _buildMenuItem(
                                  icon: Icons.star,
                                  title: "Nilai Kami",
                                  onTap: () {},
                                ),
                                _buildMenuItem(
                                  icon: Icons.logout_rounded,
                                  title: "Logout",
                                  iconColor: Colors.redAccent,
                                  onTap: () async {
                                    await UserService.logout();
                                    if (mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppRoutes.login,
                                        (route) => false,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          // FOOTER
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 72),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.radio,
                                      size: 18,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Odan FM",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "v1.0.0",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    const size = 58.0;
    if (_isLoading) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white24,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final avatarUrl = _user?.avatar;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: (size / 2) - 3,
            backgroundImage: imageProvider,
          ),
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.white24,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) =>
            _buildInitialsAvatar(size, Colors.blueGrey),
      );
    }
    return _buildInitialsAvatar(size, Colors.blueGrey);
  }

  Widget _buildInitialsAvatar(double size, Color color) {
    final name = _user?.name;
    final displayName = (name != null && name.trim().isNotEmpty)
        ? name[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.7),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
