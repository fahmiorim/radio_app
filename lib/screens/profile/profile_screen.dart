import 'package:flutter/material.dart';
import '../../config/app_routes.dart'; // pastikan import route

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text("Profil"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // foto profil
            CircleAvatar(
              radius: screenWidth * 0.1,
              backgroundImage: const AssetImage(
                "assets/user4.jpg", // ganti sesuai path gambar kamu
              ),
              backgroundColor: Colors.transparent, // biar ga ketimpa warna
            ),
            const SizedBox(height: 16),

            // nama
            const Text(
              "Agungbahari",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Info tambahan
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Email"),
              subtitle: const Text("agungbahari3007@gmail.com"),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("Nomor HP"),
              subtitle: const Text("+62 812-3456-7890"),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Alamat"),
              subtitle: const Text("Jakarta, Indonesia"),
            ),

            const SizedBox(height: 24),

            // Tombol Edit Data
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.editProfile);
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit Data"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
