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
    // batas lebar bubble maks 75% layar
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // avatar lawan bicara di kiri
          if (!isCurrentUser) ...[
            const SizedBox(width: 4),
            _Avatar(url: message.userAvatar),
            const SizedBox(width: 8),
          ],

          // bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4.0,
                    bottom: 2.0,
                    right: 4.0,
                  ),
                  child: Text(
                    isCurrentUser ? 'You' : message.username,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color:
                          isCurrentUser ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? colors.primary
                        : colors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12.0),
                      topRight: const Radius.circular(12.0),
                      bottomLeft: isCurrentUser
                          ? const Radius.circular(12.0)
                          : const Radius.circular(0),
                      bottomRight: isCurrentUser
                          ? const Radius.circular(0)
                          : const Radius.circular(12.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.onSurface.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: textTheme.bodyMedium?.copyWith(
                      color:
                          isCurrentUser ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: isCurrentUser ? 4.0 : 0,
                    left: isCurrentUser ? 0 : 4.0,
                    top: 2.0,
                  ),
                  child: Text(
                    time,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isCurrentUser) ...[
            const SizedBox(width: 4),
            _Avatar(url: message.userAvatar),
            const SizedBox(width: 8),
          ],
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
    // pakai CircleAvatar + Image.network (errorBuilder) biar fallback aman
    final hasUrl = url != null && url!.isNotEmpty;
    final colors = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 16,
      backgroundColor: colors.surfaceVariant,
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                url!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
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
