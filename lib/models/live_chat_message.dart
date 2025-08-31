import '../config/app_api_config.dart';

class LiveChatMessage {
  final int id;
  final String message;
  final int userId;
  final String name;
  final String avatar;
  final DateTime timestamp;

  LiveChatMessage({
    required this.id,
    required this.message,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.timestamp,
  });

  factory LiveChatMessage.fromJson(Map<String, dynamic> json) {
    String avatar = json['avatar']?.toString() ?? '';
    if (avatar.isNotEmpty && !avatar.startsWith('http')) {
      avatar = '${AppApiConfig.apiBaseUrl}/storage/${avatar.startsWith('/') ? avatar.substring(1) : avatar}';
    }
    return LiveChatMessage(
      id: json['id'] as int,
      message: json['message']?.toString() ?? '',
      userId: json['user_id'] as int,
      name: json['name']?.toString() ?? '',
      avatar: avatar,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
