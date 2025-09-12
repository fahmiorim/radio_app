import 'package:radio_odan_app/config/app_api_config.dart';

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
    // === Avatar handling ===
    String avatar = json['avatar']?.toString().trim() ?? '';
    if (avatar.isNotEmpty && !avatar.startsWith('http')) {
      // Normalize the asset base URL (remove trailing slash if exists)
      String baseUrl = AppApiConfig.assetBaseUrl.endsWith('/')
          ? AppApiConfig.assetBaseUrl.substring(
              0,
              AppApiConfig.assetBaseUrl.length - 1,
            )
          : AppApiConfig.assetBaseUrl;

      // Normalize the avatar path (remove leading slash if exists)
      String avatarPath = avatar.startsWith('/') ? avatar.substring(1) : avatar;

      avatar = '$baseUrl/$avatarPath';
    }

    // === ID parsing helper ===
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
      }
      return 0;
    }

    // === Timestamp parsing ===
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      final str = value.toString();
      try {
        return DateTime.parse(str).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    return LiveChatMessage(
      id: parseId(json['id']),
      message: json['message']?.toString() ?? '',
      userId: parseId(json['user_id']),
      name: json['name']?.toString() ?? '',
      avatar: avatar,
      timestamp: parseTimestamp(
        json['timestamp'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'user_id': userId,
      'name': name,
      'avatar': avatar,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
