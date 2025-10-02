import 'package:flutter/material.dart';
import 'package:radio_odan_app/services/auth_service.dart';
import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  final UserModel user;

  const ChangePasswordScreen({super.key, required this.user});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.I.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password berhasil diubah. Silakan login kembali dengan password baru.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Logout user after password change
        await AuthService.I.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } else {
        String errorMessage =
            result['message'] ?? 'Gagal mengubah password. Silakan coba lagi.';

        // Handle specific error messages
        if (result['errors'] != null) {
          final errors = result['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first?.first?.toString() ?? errorMessage;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Masukkan password baru';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password baru';
    }
    if (value != _newPasswordController.text) {
      return 'Password tidak cocok';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = _isLoading;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Ubah Password'),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Ubah Password',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat password baru yang aman dan mudah diingat',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Current Password
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      enabled: !isBusy,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan password saat ini';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Password Saat Ini',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          }),
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // New Password
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      enabled: !isBusy,
                      validator: _validateNewPassword,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          }),
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm New Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      enabled: !isBusy,
                      validator: _validateConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          }),
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isBusy ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isBusy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Back to Profile Button
                    TextButton(
                      onPressed: isBusy ? null : () => Navigator.pop(context),
                      child: Text(
                        'Kembali ke Profil',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
