import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';

class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final String time;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // System message
    if (message.isSystemMessage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant.withValues(alpha: 0.9),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // Avatar kiri (lawan bicara)
          if (!isCurrentUser) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _Avatar(url: message.userAvatar), // ← pakai URL pengirim
            ),
          ],

          // Bubble + username (untuk lawan bicara)
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                    child: Text(
                      message.username,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? colors.primary.withValues(alpha: 0.9)
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                    ),
                    boxShadow: [
                      if (!isCurrentUser)
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isCurrentUser
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: TextStyle(
                          color:
                              (isCurrentUser
                                      ? colors.onPrimary
                                      : colors.onSurfaceVariant)
                                  .withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Avatar kanan (pesan milik user sendiri)
          if (isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _Avatar(
                // kalau modelmu punya URL avatar pengirim, gunakan field yang sama
                // karena untuk pesan milikmu, pengirim = kamu
                url: message.userAvatar,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasUrl = url != null && url!.trim().isNotEmpty;

    return CircleAvatar(
      radius: 16,
      backgroundColor: colors.surfaceContainerHighest,
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                url!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/avatar.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                'assets/avatar.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
