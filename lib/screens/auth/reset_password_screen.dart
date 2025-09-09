import 'package:flutter/material.dart';
import 'package:radio_odan_app/services/auth_service.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String? token;

  const ResetPasswordScreen({super.key, String? email, this.token})
    : email = email ?? '';

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
  late String _email;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _initializeFromArguments();
  }

  void _initializeFromArguments() {
    debugPrint('[ResetPasswordScreen] Initializing from arguments...');
    final route = ModalRoute.of(context);
    debugPrint('[ResetPasswordScreen] Current route: ${route?.settings.name}');
    
    final args = route?.settings.arguments;
    debugPrint('[ResetPasswordScreen] Raw arguments: $args');
    
    if (args is Map<String, dynamic>) {
      debugPrint('[ResetPasswordScreen] Arguments is Map');
      if (args['token'] != null) {
        _tokenC.text = args['token'].toString();
        debugPrint('[ResetPasswordScreen] Set token from args: ${_tokenC.text}');
      } else {
        debugPrint('[ResetPasswordScreen] No token in args');
      }
      
      if (args['email'] != null) {
        _email = args['email'].toString();
        debugPrint('[ResetPasswordScreen] Set email from args: $_email');
      } else {
        debugPrint('[ResetPasswordScreen] No email in args');
      }
    } else if (widget.token != null) {
      _tokenC.text = widget.token!;
      debugPrint('[ResetPasswordScreen] Set token from widget: ${_tokenC.text}');
    } else {
      debugPrint('[ResetPasswordScreen] No arguments or widget token provided');
    }

    debugPrint('[ResetPasswordScreen] Final values - Token: ${_tokenC.text}');
    debugPrint('[ResetPasswordScreen] Final values - Email: $_email');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final error = await AuthService.I.resetPassword(
        email: _email,
        token: _tokenC.text,
        password: _passC.text,
        passwordConfirmation: _confirmC.text,
      );

      if (mounted) {
        if (error == null) {
          // Password reset successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password berhasil direset! Silakan login dengan password baru Anda.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _tokenC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Atur Ulang Password'), elevation: 0),
      body: Stack(
        children: [
          // Background
          const AppBackground(),

          // Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Email (readonly)
                  TextFormField(
                    initialValue: _email,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Token (readonly)
                  TextFormField(
                    controller: _tokenC,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Token Reset',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // New Password
                  TextFormField(
                    controller: _passC,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscure = !_obscure);
                        },
                      ),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan password baru';
                      }
                      if (value.length < 8) {
                        return 'Password minimal 8 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmC,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password tidak boleh kosong';
                      }
                      if (value != _passC.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Reset Password'),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
