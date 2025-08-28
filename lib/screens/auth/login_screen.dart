import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/services/auth_service.dart' as auth_service;
import 'package:radio_odan_app/services/login_service.dart' as login_service;
import 'package:radio_odan_app/config/app_colors.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool _obscureText = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final authResponse = await login_service.AuthService().login(
        email,
        password,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (authResponse != null) {
        // Save token using AuthService
        await auth_service.AuthService.saveToken(authResponse.token);

        // Show success message
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Login berhasil", style: TextStyle(color: Colors.white)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Add a small delay to show the success message
          await Future.delayed(const Duration(seconds: 1));

          // Clear all routes and navigate to home
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.bottomNav, (route) => false);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login gagal. Email atau password salah.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle back button on Android
  Future<bool> _onWillPop() async {
    // If there's no previous route, allow exit
    final canPop = Navigator.of(context).canPop();
    if (!canPop) {
      // Show confirmation dialog before exiting
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Keluar Aplikasi'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya, Keluar'),
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // Background with wave circles
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.backgroundDark],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo and title
                        // ===== HEADER =====
                        const SizedBox(height: 6),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Logo
                            ClipRRect(
                              child: Image.asset(
                                'assets/logo-white.png',
                                width: 96,
                                height: 96,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selamat datang',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Masuk untuk melanjutkan ke Radio Odan',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(.7),
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Login form
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Masukkan email Anda';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Masukkan email yang valid';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: Colors.black54,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.black54,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: _obscureText,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Masukkan password Anda';
                                    }
                                    if (value.length < 6) {
                                      return 'Password minimal 6 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                    const Text('Ingat saya'),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ForgotPasswordScreen(),
                                                ),
                                              );
                                            },
                                      child: const Text(
                                        'Lupa Password?',
                                        style: TextStyle(
                                          color: Colors.blue,
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
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Text(
                                            'MASUK',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text('ATAU'),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            // Handle Google sign in
                                          },
                                    icon: Image.asset(
                                      'assets/google.png',
                                      height: 24,
                                    ),
                                    label: const Text(
                                      'Masuk dengan Google',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.grey,
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
                                    const Text('Belum punya akun?'),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const RegisterScreen(),
                                                ),
                                              );
                                            },
                                      child: const Text(
                                        'Daftar',
                                        style: TextStyle(
                                          color: Colors.blue,
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
