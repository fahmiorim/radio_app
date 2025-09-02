import 'dart:async';
import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _initialLoading = false;
  bool _resending = false;
  bool _checking = false;

  // countdown untuk tombol kirim ulang
  static const int _cooldownSeconds = 30;
  int _countdown = _cooldownSeconds;
  Timer? _countdownTimer;

  // (opsional) auto-poll cek status tiap 6 detik
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail(); // kirim email pertama (kalau perlu dari app)
    _startCountdown();
    _startAutoPoll(); // bisa dimatikan kalau tak diinginkan
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = _cooldownSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _startAutoPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _checkStatus(silent: true),
    );
  }

  Future<void> _sendVerificationEmail() async {
    // kalau backend sudah otomatis kirim saat register, ini bisa di-skip.
    setState(() => _initialLoading = true);
    final err = await AuthService.I.resendVerificationEmail();
    if (!mounted) return;
    setState(() => _initialLoading = false);

    if (err == null) {
      _toast('Email verifikasi dikirim ke ${widget.email}', ok: true);
    } else {
      _toast(err, ok: false);
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0) return; // safety
    setState(() => _resending = true);
    final err = await AuthService.I.resendVerificationEmail();
    if (!mounted) return;
    setState(() => _resending = false);

    if (err == null) {
      _toast('Link verifikasi dikirim ulang.', ok: true);
      _startCountdown();
    } else {
      _toast(err, ok: false);
    }
  }

  Future<void> _checkStatus({bool silent = false}) async {
    setState(() => _checking = !silent);
    final verified = await AuthService.I.checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);

    if (verified) {
      _pollTimer?.cancel();
      _countdownTimer?.cancel();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.bottomNav, (r) => false);
    } else if (!silent) {
      _toast(
        'Belum terverifikasi. Coba lagi setelah klik link di email.',
        ok: false,
      );
    }
  }

  void _toast(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _goLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_initialLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.backgroundDark,
                    AppColors.backgroundDarker,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Verifikasi Email',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            size: 64,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Periksa Email Anda',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Kami telah mengirimkan link verifikasi ke:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.email,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Klik link verifikasi di email Anda, lalu kembali ke aplikasi dan tekan "Cek status".',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Kirim ulang
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_resending || _countdown > 0)
                            ? null
                            : _resend,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: AppColors.textPrimary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: _resending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.textPrimary,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _countdown > 0
                                    ? 'Kirim ulang ($_countdown s)'
                                    : 'Kirim Ulang Email',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cek status
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _checking ? null : () => _checkStatus(),
                        icon: _checking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified),
                        label: const Text('Saya sudah verifikasi, cek status'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _goLogin,
                      child: const Text(
                        'Kembali ke Halaman Login',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
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
