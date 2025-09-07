import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/providers/user_provider.dart';
import 'package:radio_odan_app/providers/theme_provider.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/services/user_service.dart';
import 'package:radio_odan_app/config/app_colors.dart';

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
    final user = userProvider.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width * 0.82,
      child: Drawer(
        backgroundColor: colorScheme.surface,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Background decorative elements
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.1),
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
                    color: colorScheme.tertiary.withOpacity(0.1),
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
                        color: colorScheme.surfaceContainerHighest,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
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
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'email@example.com',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
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
                                  context: context,
                                  icon: Icons.edit,
                                  title: "Edit Profile",
                                  onTap: () =>
                                      _navigateToEditProfile(context, user),
                                ),
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.star,
                                  title: "Nilai Kami",
                                  onTap: () {},
                                ),
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.logout_rounded,
                                  title: "Logout",
                                  iconColor: AppColors.redAccent,
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
                                // Theme Toggle
                                Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) =>
                                      _buildMenuItem(
                                        context: context,
                                        icon: Icons.light_mode,
                                        title: "Tema Gelap",
                                        onTap: () {
                                          themeProvider.toggleTheme(
                                            !themeProvider.isDarkMode,
                                          );
                                        },
                                        trailing: Switch.adaptive(
                                          value: themeProvider.isDarkMode,
                                          onChanged: (value) {
                                            themeProvider.toggleTheme(value);
                                          },
                                          activeColor: colorScheme.primary,
                                        ),
                                      ),
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
                                Divider(
                                  color: colorScheme.outline.withOpacity(0.1),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.radio,
                                      size: 18,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Odan FM",
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "v2.0.0",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.7),
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
        backgroundColor: AppColors.white24,
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
          backgroundColor: AppColors.white,
          child: CircleAvatar(
            radius: (size / 2) - 3,
            backgroundImage: imageProvider,
          ),
        ),
        placeholder: (_, __) => CircleAvatar(
          radius: size / 2,
          backgroundColor: AppColors.white24,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) =>
            _buildInitialsAvatar(size, AppColors.blueGrey, user),
      );
    }

    // Fallback ke inisial
    return _buildInitialsAvatar(size, AppColors.blueGrey, user);
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
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final defaultIconColor = iconColor ?? colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.white.withOpacity(0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.white.withOpacity(0.1)
              : colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.white.withOpacity(0.15)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: defaultIconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: AppColors.white.withOpacity(0.1),
      ),
    );
  }
}
