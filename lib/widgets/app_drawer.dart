import 'package:flutter/material.dart';
// import '../screens/profile/profile_screen.dart';
import '../config/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85, // drawer full width
      child: Drawer(
        backgroundColor: const Color(0xFF121212),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header profil
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context); // tutup drawer dulu

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    });
                  },

                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.brown,
                        child: Text(
                          "A",
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Agungbahari",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Lihat profil",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
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
}
