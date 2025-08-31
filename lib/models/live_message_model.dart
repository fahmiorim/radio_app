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
      if (avatar.startsWith('/')) {
        avatar = '${AppApiConfig.assetBaseUrl}$avatar';
      } else {
        avatar = '${AppApiConfig.assetBaseUrl}/$avatar';
      }
    }

    return LiveChatMessage(
      id: (json['id'] as num).toInt(),
      message: json['message']?.toString() ?? '',
      userId: (json['user_id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      avatar: avatar,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
