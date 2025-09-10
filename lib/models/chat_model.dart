class ChatMessage {
  final String id;
  final String userId;  // ID unik pengguna
  final String username;
  final String message;
  final DateTime timestamp;
  final String? userAvatar;
  final bool isSystemMessage;
  final bool isJoinNotification;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.message,
    required this.timestamp,
    this.userAvatar,
    this.isSystemMessage = false,
    this.isJoinNotification = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle username with proper validation
    String? rawUsername = json['username']?.toString().trim();
    String username = (rawUsername != null && rawUsername.isNotEmpty && rawUsername.toLowerCase() != 'user')
        ? rawUsername
        : 'Anonymous';
        
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      username: username,
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userAvatar: json['userAvatar']?.toString(),
      isSystemMessage: json['isSystemMessage'] == true,
      isJoinNotification: json['isJoinNotification'] == true,
    );
  }
}

class OnlineUser {
  final String id;
  final String username;
  final String? userAvatar;
  final DateTime joinTime;

  OnlineUser({
    required this.id,
    required this.username, 
    this.userAvatar, 
    required this.joinTime
  });
}
