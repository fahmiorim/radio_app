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

    int _parseId(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
      }
      return 0;
    }

    return LiveChatMessage(
      id: _parseId(json['id']),
      message: json['message']?.toString() ?? '',
      userId: _parseId(json['user_id']),
      name: json['name']?.toString() ?? '',
      avatar: avatar,
      timestamp: DateTime.parse(
        json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
