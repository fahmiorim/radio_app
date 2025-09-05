import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: AppColors.chatBackground,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.white),
                cursorColor: AppColors.white,
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: const TextStyle(color: AppColors.chatHintText),
                  filled: true,
                  fillColor: AppColors.chatInputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
                onEditingComplete: () => FocusScope.of(context).unfocus(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.white, size: 20),
              padding: const EdgeInsets.all(12),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.liveIndicator,
                shape: const CircleBorder(),
              ),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
