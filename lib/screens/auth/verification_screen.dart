import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/providers/auth_provider.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _initialLoading = false;
  bool _resending = false;

  // spinner di tombol "cek status"
  bool _checking = false;

  // guard supaya _checkStatus tidak dipanggil berulang-ulang
  bool _isChecking = false;

  // status tombol kirim ulang
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    // Schedule the email to be sent after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationEmail(); // kirim email pertama (skip kalau backend sudah auto-send)
    });
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _initialLoading = true);

    final authProvider = context.read<AuthProvider>();
    final err = await authProvider.resendVerificationEmail();

    if (!mounted) return;
    setState(() => _initialLoading = false);

    if (err == null) {
      _toast('Email verifikasi dikirim ke ${widget.email}', ok: true);
      // cooldown awal setelah kirim pertama
      setState(() => _canResend = false);
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted) setState(() => _canResend = true);
      });
    } else {
      _toast(err, ok: false);
    }
  }

  Future<void> _resend() async {
    if (!_canResend || _resending) return;

    setState(() {
      _resending = true;
      _canResend = false;
    });

    final authProvider = context.read<AuthProvider>();
    final err = await authProvider.resendVerificationEmail();

    if (!mounted) return;

    if (err == null) {
      _toast('Link verifikasi dikirim ulang.', ok: true);
      // cooldown 30 detik sebelum bisa kirim lagi
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted) setState(() => _canResend = true);
      });
    } else {
      setState(() => _canResend = true);
      _toast(err, ok: false);
    }

    if (mounted) setState(() => _resending = false);
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _checking = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final verified = await authProvider.checkEmailVerified();

      if (!mounted) return;

      if (verified) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.bottomNav, (r) => false);
      } else {
        _toast(
          'Belum terverifikasi. Coba lagi setelah klik link di email.',
          ok: false,
        );
      }
    } catch (e) {
      debugPrint('Error checking verification status: $e');
      if (mounted) {
        _toast('Gagal memeriksa status verifikasi.', ok: false);
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _checking = false;
      });
    }
  }

  void _toast(String msg, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.green : AppColors.red,
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
        body: Center(child: CircularProgressIndicator(color: AppColors.white)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Builder(
              builder: (context) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.background,
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
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
                        color: AppColors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.2),
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
                      child: OutlinedButton(
                        onPressed: (_canResend && !_resending) ? _resend : null,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: AppColors.textPrimary,
                            width: 1.5,
                          ),
                        ),
                        child: _resending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _canResend
                                    ? 'Kirim Ulang Email'
                                    : 'Tunggu 30 detik',
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cek status (manual only)
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _checking ? null : _checkStatus,
                        icon: _checking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
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
