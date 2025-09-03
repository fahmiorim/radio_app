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

  static int _parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final str = value.toString();
    try {
      return DateTime.parse(str).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static String _normalizeAvatar(dynamic raw) {
    String avatar = raw?.toString().trim() ?? '';
    if (avatar.isEmpty) return '';
    if (avatar.startsWith('http')) return avatar;
    if (avatar.startsWith('/')) {
      return '${AppApiConfig.assetBaseUrl}$avatar';
    }
    return '${AppApiConfig.assetBaseUrl}/$avatar';
  }

  factory LiveChatMessage.fromJson(Map<String, dynamic> json) {
    return LiveChatMessage(
      id: _parseId(json['id']),
      message: json['message']?.toString() ?? '',
      userId: _parseId(json['user_id'] ?? json['userId']),
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      avatar: _normalizeAvatar(json['avatar']),
      timestamp: _parseTimestamp(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LiveChatMessage && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
