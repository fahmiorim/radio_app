import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../config/app_routes.dart';
import '../services/user_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigateToEditProfile(BuildContext context, UserModel? user) {
    if (user != null) {
      Navigator.pop(context);
      Navigator.pushNamed(
        context,
        AppRoutes.editProfile,
        arguments: {'user': user},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user; // UserModel?
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
              SafeArea(
                child: Column(
                  children: [
                    // Header user
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
                          _buildProfileAvatar(userProvider),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Nama Pengguna',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'email@example.com',
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

                    // Menu
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
                                  onTap: () =>
                                      _navigateToEditProfile(context, user),
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
                                    if (context.mounted) {
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

                          // Footer versi
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

  Widget _buildProfileAvatar(UserProvider userProvider) {
    const size = 58.0;
    final user = userProvider.user;

    if (userProvider.isLoading) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white24,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final url =
        user?.avatarUrl ?? ''; // ⬅️ pakai getter yang sudah dinormalisasi

    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: (size / 2) - 3,
            backgroundImage: imageProvider,
          ),
        ),
        placeholder: (_, __) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.white24,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) =>
            _buildInitialsAvatar(size, Colors.blueGrey, user),
      );
    }

    // Fallback ke inisial
    return _buildInitialsAvatar(size, Colors.blueGrey, user);
  }

  Widget _buildInitialsAvatar(double size, Color color, UserModel? user) {
    // Catatan: jika `name` di UserModel non-nullable (String), akses pakai user?.name aman dengan null-check di user.
    final initial = (user != null && user.name.trim().isNotEmpty)
        ? user.name[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initial,
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
          style: const TextStyle(
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
