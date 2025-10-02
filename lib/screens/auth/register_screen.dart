import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/providers/auth_provider.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _obscure = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nama lengkap harus diisi';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email harus diisi';
    if (!RegExp(r'^[^@]+@[^\s]+\.[^\s]+').hasMatch(v)) {
      return 'Email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password harus diisi';
    if (v.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Konfirmasi password harus diisi';
    if (v != _passC.text) return 'Konfirmasi password tidak cocok';
    return null;
  }

  double _passwordStrength(String p) {
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(p)) score++;
    return (score / 5).clamp(0, 1);
  }

  Future<void> _register() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (!_agreeTerms) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Anda harus menyetujui Syarat & Ketentuan'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    try {
      final errorMessage = await auth.register(
        _nameC.text.trim(),
        _emailC.text.trim(),
        _passC.text,
      );

      if (!mounted) return;

      if (errorMessage == null) {
        if (!mounted) return;
      }

      // If errorMessage is null, registration was successful
      if (errorMessage == null) {
        final email = _emailC.text.trim();
        try {
          await Navigator.pushReplacementNamed(
            context,
            AppRoutes.verification,
            arguments: email,
          );
        } catch (e) {
          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal pindah ke halaman verifikasi: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Google Sign-In for registration
  Future<void> _registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        final auth = context.read<AuthProvider>();
        final error = await auth.loginWithFirebase(user);

        if (!mounted) return;

        if (error == null) {
          // Successfully registered and logged in with Google
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.bottomNav, (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pendaftaran dengan Google gagal: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.54),
      ),
      labelStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      prefixIcon: Icon(
        icon,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      suffixIcon: trailing,
      filled: true,
      fillColor: colorScheme.surface.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.onSurface, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      errorStyle: TextStyle(color: colorScheme.error),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loading = context.watch<AuthProvider>().loading;
    final strength = _passwordStrength(_passC.text);

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Buat Akun Baru',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Daftar untuk melanjutkan ke Radio Odan',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameC,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          context,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline,
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailC,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          context,
                          label: 'Email',
                          hint: 'contoh@email.com',
                          icon: Icons.email_outlined,
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passC,
                        obscureText: _obscure,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          context,
                          label: 'Password',
                          hint: 'Minimal 8 karakter',
                          icon: Icons.lock_outline,
                          trailing: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: _validatePassword,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),

                      LinearProgressIndicator(
                        value: strength,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          strength < 0.7
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _confirmC,
                        obscureText: _obscure,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          context,
                          label: 'Konfirmasi Password',
                          hint: 'Ketik ulang password',
                          icon: Icons.lock_outline,
                        ),
                        validator: _validateConfirm,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Checkbox(
                            value: _agreeTerms,
                            onChanged: loading
                                ? null
                                : (v) =>
                                      setState(() => _agreeTerms = v ?? false),
                            fillColor: WidgetStateProperty.resolveWith<Color>(
                              (states) => states.contains(WidgetState.selected)
                                  ? colorScheme.primary
                                  : colorScheme.surface,
                            ),
                            side: BorderSide(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              width: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Saya menyetujui ',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Syarat & Ketentuan',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' dan ',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Kebijakan Privasi',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : const Text(
                                'Daftar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'atau daftar dengan',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed: loading ? null : _registerWithGoogle,
                        icon: Image.asset(
                          'assets/google.png',
                          width: 24,
                          height: 24,
                        ),
                        label: Text(
                          'Google',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun? ',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Masuk di sini',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (loading)
            Container(
              color: colorScheme.onSurface.withValues(alpha: 0.26),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
