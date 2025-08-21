class ChatMessage {
  final String id;
  final String username;
  final String message;
  final DateTime timestamp;
  final String? userAvatar;
  final bool isSystemMessage;
  final bool isJoinNotification;

  ChatMessage({
    required this.id,
    required this.username,
    required this.message,
    required this.timestamp,
    this.userAvatar,
    this.isSystemMessage = false,
    this.isJoinNotification = false,
  });
}

class OnlineUser {
  final String username;
  final String? userAvatar;
  final DateTime joinTime;

  OnlineUser({required this.username, this.userAvatar, required this.joinTime});
}
