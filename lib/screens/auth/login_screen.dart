import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/providers/auth_provider.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _rememberMe = false;
  bool _obscure = true;

  // guard untuk mencegah double submit
  bool _emailLoginBusy = false;
  bool _googleLoginBusy = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _unfocusAll() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _showSnack({
    required String message,
    bool success = false,
  }) async {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: theme.colorScheme.surface,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.surface,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: success
            ? theme.colorScheme.primary
            : theme.colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Masukkan email Anda';
    final val = v.trim();
    // cek simpel
    if (!val.contains('@') || !val.contains('.')) {
      return 'Masukkan email yang valid';
    }
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Masukkan password Anda';
    if (v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  Future<void> _login() async {
    if (_emailLoginBusy || _googleLoginBusy) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    _unfocusAll();
    setState(() => _emailLoginBusy = true);

    try {
      final auth = context.read<AuthProvider>();
      final err = await auth.login(_emailC.text.trim(), _passC.text);

      if (!mounted) return;

      if (err == null) {
        await _showSnack(message: 'Login berhasil', success: true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.bottomNav, (route) => false);
      } else {
        await _showSnack(message: err, success: false);
      }
    } catch (e) {
      if (mounted) {
        await _showSnack(message: 'Terjadi kesalahan: $e', success: false);
      }
    } finally {
      if (mounted) setState(() => _emailLoginBusy = false);
    }
  }

  // Login via Google + FirebaseAuth, lalu serahkan ke backend via AuthProvider
  Future<void> _signInWithGoogle() async {
    if (_googleLoginBusy || _emailLoginBusy) return;

    _unfocusAll();
    setState(() => _googleLoginBusy = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // user batal
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);

      final user = userCred.user;
      if (user != null) {
        await context.read<AuthProvider>().loginWithFirebase(user);
        if (!mounted) return;
        await _showSnack(message: 'Login Google berhasil', success: true);
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.bottomNav, (_) => false);
      } else {
        await _showSnack(
          message: 'Login Google gagal: user null',
          success: false,
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      // mapping error umum firebase
      String msg = 'Login Google gagal';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          msg = 'Email sudah terhubung metode lain.';
          break;
        case 'invalid-credential':
          msg = 'Kredensial tidak valid.';
          break;
        case 'operation-not-allowed':
          msg = 'Login Google belum diaktifkan.';
          break;
        case 'user-disabled':
          msg = 'Akun dinonaktifkan.';
          break;
        case 'user-not-found':
          msg = 'Pengguna tidak ditemukan.';
          break;
        case 'wrong-password':
          msg = 'Password salah.';
          break;
        case 'invalid-verification-code':
        case 'invalid-verification-id':
          msg = 'Verifikasi tidak valid.';
          break;
      }
      await _showSnack(message: '$msg (${e.code})', success: false);
    } catch (e) {
      await _showSnack(message: 'Login Google gagal: $e', success: false);
    } finally {
      if (mounted) setState(() => _googleLoginBusy = false);
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
    // Jika AuthProvider juga punya state loading global, tetap aman karena kita pakai guard lokal.
    final providerLoading = context.watch<AuthProvider>().loading;
    final isBusy = _emailLoginBusy || _googleLoginBusy || providerLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final allow = await _onWillPop();
        if (allow) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            const AppBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selamat datang',
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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: .7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.92,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailC,
                              focusNode: _emailFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(
                                context,
                              ).requestFocus(_passFocus),
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                              enabled: !_emailLoginBusy && !_googleLoginBusy,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passC,
                              focusNode: _passFocus,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              validator: _passwordValidator,
                              enabled: !_emailLoginBusy && !_googleLoginBusy,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: isBusy
                                      ? null
                                      : (val) => setState(
                                          () => _rememberMe = val ?? false,
                                        ),
                                ),
                                Text(
                                  'Ingat saya',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.forgotPassword,
                                        ),
                                  child: Text(
                                    'Lupa Password?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
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
                                onPressed: isBusy ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _emailLoginBusy
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'MASUK',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onPrimary,
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
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
                                onPressed: isBusy ? null : _signInWithGoogle,
                                icon: Image.asset(
                                  'assets/google.png',
                                  height: 24,
                                ),
                                label: Text(
                                  'Masuk dengan Google',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
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
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                TextButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.register,
                                        ),
                                  child: Text(
                                    'Daftar',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
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
          ],
        ),
      ),
    );
  }
}
