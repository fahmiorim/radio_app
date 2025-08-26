import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/services/user_service.dart';
import 'package:radio_odan_app/config/logger.dart';
import 'package:radio_odan_app/config/app_api_config.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final Function()? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.user,
    this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  File? _imageFile;
  final picker = ImagePicker();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
  }

  ImageProvider _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (widget.user.avatar != null && widget.user.avatar!.isNotEmpty) {
      // Ensure the URL is properly formatted
      String avatarUrl = widget.user.avatar!;

      // If it's already a full URL, use it as is
      if (avatarUrl.startsWith('http')) {
        return NetworkImage(avatarUrl);
      }

      // Handle local file paths
      if (avatarUrl.startsWith('file:///')) {
        return FileImage(File(avatarUrl.replaceFirst('file://', '')));
      }

      // For relative paths, prepend the base URL
      final baseUrl = AppApiConfig.baseUrl;
      if (avatarUrl.startsWith('/')) {
        return NetworkImage('$baseUrl$avatarUrl');
      } else {
        // If it's just a filename, prepend the storage path
        return NetworkImage('$baseUrl/storage/$avatarUrl');
      }
    }
    return const AssetImage("assets/user1.jpg");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await UserService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        avatarPath: _imageFile?.path,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Update the user data in the parent widget
        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!();
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Profil berhasil diperbarui'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Close the edit screen after a short delay
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, true); // Pass true to indicate success
          }
        }
      } else {
        // Show error message if update was not successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal memperbarui profil'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      logger.e('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (e is DioException && e.response?.data != null && e.response!.data is Map && e.response!.data['message'] != null)
                  ? e.response!.data['message']
                  : 'Terjadi kesalahan: ${e.toString()}'
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    backgroundImage: _getProfileImage(),
                    onBackgroundImageError: (exception, stackTrace) {
                      // This will be handled by the fallback in _getProfileImage
                    },
                    child:
                        _imageFile == null &&
                            (widget.user.avatar == null ||
                                widget.user.avatar!.isEmpty)
                        ? const Icon(Icons.person, size: 40)
                        : null,
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
