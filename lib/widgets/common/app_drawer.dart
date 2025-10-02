import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/providers/auth_provider.dart';
import 'package:radio_odan_app/providers/user_provider.dart';
import 'package:radio_odan_app/providers/theme_provider.dart';
import 'package:radio_odan_app/config/app_routes.dart';

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
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Background dekoratif
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.1),
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
                    color: colorScheme.tertiary.withValues(alpha: 0.1),
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
                            color: colorScheme.outline.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildProfileAvatar(context, userProvider),
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
                                  icon: Icons.lock_reset_rounded,
                                  title: "Ganti Password",
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.changePassword,
                                      arguments: {'user': user},
                                    );
                                  },
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
                                  iconColor: colorScheme.error,
                                  onTap: () async {
                                    await context.read<AuthProvider>().logout();
                                    if (context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppRoutes.login,
                                        (route) => false,
                                      );
                                    }
                                  },
                                ),
                                // Toggle Tema
                                Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) {
                                    final bool isDark =
                                        themeProvider.isDarkMode;
                                    return _buildMenuItem(
                                      context: context,
                                      icon: isDark
                                          ? Icons.light_mode
                                          : Icons.dark_mode,
                                      title: isDark
                                          ? "Tema Terang"
                                          : "Tema Gelap",
                                      onTap: () {
                                        themeProvider.toggleTheme(!isDark);
                                      },
                                      trailing: Switch.adaptive(
                                        value: isDark,
                                        onChanged: (value) {
                                          themeProvider.toggleTheme(value);
                                        },
                                        activeColor: colorScheme.primary,
                                        activeTrackColor:
                                            colorScheme.primaryContainer,
                                        thumbColor:
                                            WidgetStateProperty.resolveWith<
                                              Color
                                            >(
                                              (states) =>
                                                  states.contains(
                                                    WidgetState.selected,
                                                  )
                                                  ? colorScheme.onPrimary
                                                  : colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Footer versi (dinamis dari package_info_plus)
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 72),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Divider(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.1,
                                  ),
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
                                FutureBuilder<PackageInfo>(
                                  future: PackageInfo.fromPlatform(),
                                  builder: (context, snap) {
                                    final style = TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                      fontSize: 12,
                                    );
                                    if (!snap.hasData) {
                                      return Text("v—", style: style);
                                    }
                                    final info = snap.data!;
                                    return Text(
                                      "v${info.version} (${info.buildNumber})",
                                      style: style,
                                    );
                                  },
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

  Widget _buildProfileAvatar(BuildContext context, UserProvider userProvider) {
    const size = 58.0;
    final user = userProvider.user;
    final colorScheme = Theme.of(context).colorScheme;

    if (userProvider.isLoading) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final url = user?.avatarUrl ?? '';

    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundColor: colorScheme.surface,
          child: CircleAvatar(
            radius: (size / 2) - 3,
            backgroundImage: imageProvider,
          ),
        ),
        placeholder: (_, _) => CircleAvatar(
          radius: size / 2,
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => _buildInitialsAvatar(size, colorScheme, user),
      );
    }

    // Fallback ke inisial
    return _buildInitialsAvatar(size, colorScheme, user);
  }

  Widget _buildInitialsAvatar(
    double size,
    ColorScheme colorScheme,
    UserModel? user,
  ) {
    final initial = (user != null && user.name.trim().isNotEmpty)
        ? user.name[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.surfaceContainerHighest,
      child: Text(
        initial,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
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
            ? colorScheme.onSurface.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.onSurface.withValues(alpha: 0.1)
              : colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.onSurface.withValues(alpha: 0.15)
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
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.1),
      ),
    );
  }
}
