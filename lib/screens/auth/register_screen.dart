import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:radio_odan_app/services/login_service.dart';
import '../../config/app_routes.dart';
import 'package:radio_odan_app/config/logger.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  bool agreeTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!agreeTerms) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda harus menyetujui Syarat & Ketentuan'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      final authResponse = await AuthService().register(name, email, password);
      if (!mounted) return;

      if (authResponse != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registrasi berhasil'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.bottomNav);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registrasi gagal'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.bottomNav);
      } else {
        logger.w('⚠️ Gagal login Google');
      }
    } catch (e) {
      logger.e('❌ Error login Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  String _passwordLabel(double s) {
    if (s < 0.34) return 'Lemah';
    if (s < 0.67) return 'Cukup';
    return 'Kuat';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = _passwordStrength(_passwordController.text);

    return Scaffold(
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

          // ===== CONTENT =====
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'Buat Akun Baru',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // ===== NAMA =====
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              context,
                              label: 'Nama',
                              hint: 'Nama lengkap',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Nama tidak boleh kosong';
                              if (v.trim().length < 3)
                                return 'Nama minimal 3 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

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
                              if (value == null || value.isEmpty)
                                return 'Email tidak boleh kosong';
                              final emailRegex = RegExp(r'^.+@.+\..+$');
                              if (!emailRegex.hasMatch(value))
                                return 'Masukkan email yang valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // ===== PASSWORD =====
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              context,
                              label: 'Password',
                              hint: 'Minimal 8 karakter',
                              icon: Icons.lock_outline,
                              trailing: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Password tidak boleh kosong';
                              if (value.length < 6)
                                return 'Password minimal 6 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // ===== PASSWORD STRENGTH =====
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: strength,
                                    minHeight: 8,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceVariant
                                        .withOpacity(.6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _passwordLabel(strength),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ===== KONFIRMASI PASSWORD =====
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _register(),
                            decoration: _inputDecoration(
                              context,
                              label: 'Ulangi Password',
                              hint: 'Ketik ulang password',
                              icon: Icons.lock_person_outlined,
                              trailing: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Harap ulangi password';
                              if (value != _passwordController.text)
                                return 'Password tidak sama';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // ===== SYARAT & KETENTUAN =====
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: agreeTerms,
                                onChanged: (v) =>
                                    setState(() => agreeTerms = v ?? false),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => agreeTerms = !agreeTerms),
                                  child: RichText(
                                    text: TextSpan(
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                      children: [
                                        const TextSpan(
                                          text: 'Saya setuju dengan ',
                                        ),
                                        TextSpan(
                                          text: 'Syarat & Ketentuan',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          // onTap bisa diarahkan ke halaman terms jika tersedia
                                        ),
                                        const TextSpan(text: ' dan '),
                                        TextSpan(
                                          text: 'Kebijakan Privasi',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // ===== BUTTON DAFTAR =====
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: (!agreeTerms || _isLoading)
                                  ? null
                                  : _register,
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
                                        'Daftar',
                                        key: ValueKey('text'),
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ===== SUDAH PUNYA AKUN =====
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Sudah punya akun? '),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.login,
                                ),
                                child: Text(
                                  'Masuk di sini',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // ===== DIVIDER =====
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
                                'Daftar / Masuk dengan Google',
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

          // ===== LOADING OVERLAY TIPIS =====
          if (_isLoading)
            IgnorePointer(
              ignoring: true,
              child: Container(color: Colors.black.withOpacity(0.04)),
            ),
        ],
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
      fillColor: theme.colorScheme.surface.withOpacity(.92),
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

/// Kartu bergaya glassmorphism (sama seperti di Login)
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
