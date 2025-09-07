import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/config/app_theme.dart';
import 'package:radio_odan_app/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final auth = context.read<AuthProvider>();
    final err = await auth.login(_emailC.text.trim(), _passC.text);

    if (!mounted) return;

    if (err == null) {
      // sukses
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.surface,
              ),
              const SizedBox(width: 10),
              Text(
                'Login berhasil',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.surface,
                ),
              ),
            ],
          ),
          backgroundColor: theme.colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      // beri jeda kecil biar snackbar kebaca
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.bottomNav, (route) => false);
    } else {
      // gagal
      final theme = Theme.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            err,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.surface,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  // Placeholder untuk Google Sign-In (akan diisi nanti)
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      if (user != null) {
        await context.read<AuthProvider>().loginWithFirebase(user);
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.bottomNav,
        (_) => false,
      );
    } catch (e) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login Google gagal: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.surface,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  // Handle back button pada Android
  Future<bool> _onWillPop() async {
    final canPop = Navigator.of(context).canPop();
    if (!canPop) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Keluar Aplikasi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Tidak',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Ya, Keluar',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading = context.watch<AuthProvider>().loading;
    final isDarkMode = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final allow = await _onWillPop();
        if (allow) await SystemNavigator.pop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background bubbles
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.background,
                child: Stack(
                  children: [
                    AppTheme.bubble(
                      context: context,
                      size: 200,
                      top: -50,
                      right: -50,
                      opacity: isDarkMode ? 0.1 : 0.03,
                      usePrimaryColor: true,
                    ),
                    AppTheme.bubble(
                      context: context,
                      size: 150,
                      bottom: -30,
                      left: -30,
                      opacity: isDarkMode ? 0.08 : 0.03,
                      usePrimaryColor: true,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),

                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo-white.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Selamat datang',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk untuk melanjutkan ke Radio Odan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(.7),
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Card Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                                TextFormField(
                                  controller: _emailC,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Masukkan email Anda';
                                    if (!v.contains('@'))
                                      return 'Masukkan email yang valid';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passC,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Masukkan password Anda';
                                    if (v.length < 6)
                                      return 'Password minimal 6 karakter';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: loading
                                          ? null
                                          : (val) => setState(
                                              () => _rememberMe = val ?? false,
                                            ),
                                    ),
                                    Text(
                                      'Ingat saya',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: loading
                                          ? null
                                          : () => Navigator.pushNamed(
                                              context,
                                              AppRoutes.forgotPassword,
                                            ),
                                      child: Text(
                                        'Lupa Password?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: loading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                          )
                                        : Text(
                                            'MASUK',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'ATAU',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: loading
                                        ? null
                                        : _signInWithGoogle,
                                    icon: Image.asset(
                                      'assets/google.png',
                                      height: 24,
                                    ),
                                    label: Text(
                                      'Masuk dengan Google',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Belum punya akun?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                    TextButton(
                                      onPressed: loading
                                          ? null
                                          : () => Navigator.pushNamed(
                                              context,
                                              AppRoutes.register,
                                            ),
                                      child: Text(
                                        'Daftar',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
