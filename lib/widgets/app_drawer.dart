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
      logger.e('Error loading user profile in drawer: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Drawer(
        backgroundColor: const Color(0xFF121212),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Profil
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushNamed(context, AppRoutes.profile);
                      });
                    },
                    child: Row(
                      children: [
                        _buildProfileAvatar(),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user?.name ?? 'Pengguna',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _user?.email ?? '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Lihat profil',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              Divider(color: Colors.grey.shade800, thickness: 0.8),

              // Menu
              // ListTile(
              //   leading: const Icon(Icons.person, color: Colors.white),
              //   title: const Text(
              //     "Lihat Profil",
              //     style: TextStyle(color: Colors.white),
              //   ),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => const ProfilScreen()),
              //     );
              //   },
              // ),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.white),
                title: const Text(
                  "Nilai Kami",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final size = 56.0;

    if (_user?.avatar?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: _user!.avatar!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 28,
          backgroundColor: theme.primaryColor,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: 28,
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) =>
            _buildInitialsAvatar(theme, textTheme, size),
      );
    }

    return _buildInitialsAvatar(theme, textTheme, size);
  }

  Widget _buildInitialsAvatar(
    ThemeData theme,
    TextTheme textTheme,
    double size,
  ) {
    final displayName = _user?.name?.trim().isNotEmpty == true
        ? _user!.name![0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.primaryColor,
      child: Text(
        displayName,
        style: textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
