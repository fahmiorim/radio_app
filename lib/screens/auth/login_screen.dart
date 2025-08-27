import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:radio_odan_app/services/login_service.dart';
import '../../config/app_routes.dart';
import 'package:radio_odan_app/config/logger.dart';

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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      final authResponse = await AuthService().login(email, password);
      if (!mounted) return;

      if (authResponse != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Login berhasil", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.bottomNav,
          (route) => false, // This removes all previous routes
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.toString().replaceFirst("Exception: ", ""),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return;

      final authResponse = await AuthService().loginWithGoogle(idToken);
      if (authResponse != null) {
        logger.i("✅ Login sukses");
        logger.i("Token: ${authResponse.token}");
        logger.i("User: ${authResponse.user.name}");
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.bottomNav,
          (route) => false, // This removes all previous routes
        );
      } else {
        logger.w("⚠️ Gagal login Google");
      }
    } catch (e) {
      logger.e("❌ Error login Google: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Prevent going back to previous screen if it's the login screen
        return !Navigator.of(context).userGestureInProgress;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ===== BACKGROUND GRADIENT + RADIO WAVES =====
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0B63E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // dekorasi "gelombang radio" halus
            Positioned(
              top: -80,
              right: -40,
              child: _WaveCircle(size: 220, opacity: .12),
            ),
            Positioned(
              bottom: -60,
              left: -30,
              child: _WaveCircle(size: 180, opacity: .10),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _GlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // ===== HEADER =====
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/logo-white.png',
                                width: 84,
                                height: 84,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Selamat datang 👋',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Masuk untuk melanjutkan ke Radio Odan',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  .7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ===== EMAIL =====
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                context,
                                label: 'Email',
                                hint: 'nama@contoh.com',
                                icon: Icons.alternate_email,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                final emailRegex = RegExp(r'^.+@.+\..+$');
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Masukkan email yang valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // ===== PASSWORD =====
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscureText,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              decoration: _inputDecoration(
                                context,
                                label: 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                trailing: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureText = !_obscureText,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                if (value.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // ===== REMEMBER + FORGOT =====
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (v) =>
                                      setState(() => rememberMe = v ?? false),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Text('Ingat saya'),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.forgotPassword,
                                  ),
                                  child: const Text('Lupa password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // ===== BUTTON LOGIN =====
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _login,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isLoading
                                      ? const SizedBox(
                                          key: ValueKey('loader'),
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.6,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Masuk',
                                          key: ValueKey('text'),
                                          style: TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ===== REGISTER =====
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Belum punya akun? '),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.register,
                                  ),
                                  child: Text(
                                    'Daftar sekarang',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // ===== DIVIDER “ATAU” =====
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: theme.dividerColor.withOpacity(.3),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'atau',
                                    style: TextStyle(color: theme.hintColor),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: theme.dividerColor.withOpacity(.3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // ===== GOOGLE BUTTON =====
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _loginWithGoogle,
                                icon: Image.asset(
                                  'assets/google.png',
                                  width: 22,
                                  height: 22,
                                ),
                                label: const Text(
                                  'Login dengan Google',
                                  style: TextStyle(fontSize: 15),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ===== LOADING OVERLAY (opsional) =====
            if (_isLoading)
              IgnorePointer(
                ignoring: true,
                child: Container(color: Colors.black.withOpacity(0.04)),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: trailing,
      filled: true,
      fillColor: theme.colorScheme.surface.withOpacity(.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withOpacity(.6),
          width: 1.4,
        ),
      ),
    );
  }
}

/// Kartu bergaya “glassmorphism”
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          decoration: BoxDecoration(
            color: surface.withOpacity(.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(.22)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 40,
                spreadRadius: -12,
                offset: Offset(0, 24),
                color: Color(0x33000000),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Lingkaran dekoratif seperti “gelombang radio”
class _WaveCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _WaveCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(opacity),
            Colors.white.withOpacity(0),
          ],
        ),
      ),
    );
  }
}
