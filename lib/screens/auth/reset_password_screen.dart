import 'package:flutter/material.dart';
import 'package:radio_odan_app/services/auth_service.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; // bisa diisi otomatis dari argumen
  final String? token; // bisa null kalau user paste manual
  const ResetPasswordScreen({super.key, required this.email, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) _tokenC.text = widget.token!;
  }

  @override
  void dispose() {
    _tokenC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _loading = true);
    final err = await AuthService.I.resetPassword(
      email: widget.email.trim(),
      token: _tokenC.text.trim(),
      password: _passC.text,
      passwordConfirmation: _confirmC.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final theme = Theme.of(context);

    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password berhasil direset. Silakan login.'),
          backgroundColor: theme.colorScheme.onPrimary,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Stack(
        children: [
          const AppBackground(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
              TextFormField(
                controller: _tokenC,
                decoration: const InputDecoration(
                  labelText: 'Token dari email',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Token wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passC,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password wajib diisi';
                  if (v.length < 8) return 'Minimal 8 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmC,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    (v != _passC.text) ? 'Konfirmasi tidak cocok' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Reset Password'),
                ),
              ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
