import 'package:flutter/material.dart';
import '../../models/chat_model.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              child: Text(
                message.username.isNotEmpty
                    ? message.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser) ...[
                  Text(
                    message.username,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? const Color(0xFF1E88E5)
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    message.message,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14.0),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[500], fontSize: 10.0),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8.0),
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey,
              child: Text('A', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
