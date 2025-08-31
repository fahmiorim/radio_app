import 'package:intl/intl.dart';

class LiveChatStatus {
  final bool isLive;
  final String title;
  final String description;
  final DateTime? startedAt;
  final int likes;
  final bool liked;
  final int listenerCount;

  LiveChatStatus({
    required this.isLive,
    required this.title,
    required this.description,
    required this.startedAt,
    required this.likes,
    required this.liked,
    required this.listenerCount,
  });

  factory LiveChatStatus.fromJson(Map<String, dynamic> json) {
    DateTime? started;
    final raw = json['started_at'];
    if (raw is String && raw.isNotEmpty) {
      try {
        started = DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
      } catch (_) {}
    }
    return LiveChatStatus(
      isLive: json['is_live'] == true,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startedAt: started,
      likes: json['likes'] is int
          ? json['likes']
          : int.tryParse(json['likes']?.toString() ?? '') ?? 0,
      liked: json['liked'] == true,
      listenerCount: json['listener_count'] is int
          ? json['listener_count']
          : int.tryParse(json['listener_count']?.toString() ?? '') ?? 0,
    );
  }

  LiveChatStatus copyWith({
    bool? isLive,
    String? title,
    String? description,
    DateTime? startedAt,
    int? likes,
    bool? liked,
    int? listenerCount,
  }) {
    return LiveChatStatus(
      isLive: isLive ?? this.isLive,
      title: title ?? this.title,
      description: description ?? this.description,
      startedAt: startedAt ?? this.startedAt,
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,
      listenerCount: listenerCount ?? this.listenerCount,
    );
  }
}
