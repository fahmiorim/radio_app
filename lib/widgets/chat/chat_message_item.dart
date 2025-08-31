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
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Other user's avatar (left side)
          if (!isCurrentUser) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 8.0),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  image: message.userAvatar != null && message.userAvatar!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(message.userAvatar!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) =>
                              const AssetImage('assets/avatar.png'),
                        )
                      : const DecorationImage(
                          image: AssetImage('assets/avatar.png'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ],
          
          // Current user's message bubble (right side)
          if (isCurrentUser) ...[
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                        bottomLeft: Radius.circular(12.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0, top: 2.0),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
          ],

          // Other user's message bubble (left side)
          if (!isCurrentUser) ...[
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                    child: Text(
                      message.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.0,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                        bottomRight: Radius.circular(12.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message.message,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15.0,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, top: 2.0),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
