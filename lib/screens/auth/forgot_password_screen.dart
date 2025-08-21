import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), // dark container
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.blueAccent,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                const Text(
                  "Forgot Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // white text for dark theme
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  "Enter your email to reset your password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey, // slightly grey for dark theme
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  "Enter the email address associated with your account and we'll send you a link to reset your password.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Email TextField
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: "you@example.com",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Send Password Reset Link Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: fungsi kirim link reset
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Send Password Reset Link",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // Back to login
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // kembali ke halaman login
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Remember your password? ",
                      style: const TextStyle(
                        color: Colors.white, // putih
                        decoration: TextDecoration.none,
                      ),
                      children: const [
                        TextSpan(
                          text: "Back to login",
                          style: TextStyle(
                            color: Colors.blueAccent, // biru
                            decoration: TextDecoration.underline,
                          ),
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
    );
  }
}
