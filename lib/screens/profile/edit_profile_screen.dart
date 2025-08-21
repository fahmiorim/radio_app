import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _imageFile;
  final picker = ImagePicker();

  // Controller untuk textfield
  final TextEditingController _nameController = TextEditingController(
    text: "Agungbahari",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "agungbahari3007@gmail.com",
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "+62 812-3456-7890",
  );
  final TextEditingController _addressController = TextEditingController(
    text: "Jakarta, Indonesia",
  );

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Data")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Avatar + tombol edit foto
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : const AssetImage("assets/user4.jpg") as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nama
              TextField(
                controller: _nameController,
                decoration: _inputDecoration(
                  label: "Nama",
                  hint: "Masukkan nama lengkap",
                  icon: Icons.person,
                ),
              ),
              const SizedBox(height: 20),

              // Email
              TextField(
                controller: _emailController,
                decoration: _inputDecoration(
                  label: "Email",
                  hint: "contoh@email.com",
                  icon: Icons.email,
                ),
              ),
              const SizedBox(height: 20),

              // Nomor HP
              TextField(
                controller: _phoneController,
                decoration: _inputDecoration(
                  label: "Nomor HP",
                  hint: "08xxxx",
                  icon: Icons.phone,
                ),
              ),
              const SizedBox(height: 20),

              // Alamat
              TextField(
                controller: _addressController,
                decoration: _inputDecoration(
                  label: "Alamat",
                  hint: "Masukkan alamat",
                  icon: Icons.location_on,
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Simpan data (sementara balik ke profil)
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Simpan"),
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
      ),
    );
  }

  // Reusable decoration biar rapih
  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.brown, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}
