class LiveChatStatus {
  final bool isLive;
  final String title;
  final String description;
  final DateTime? startedAt;
  final int likes;
  final bool liked;
  final int listenerCount;
  final int? roomId;

  LiveChatStatus({
    required this.isLive,
    required this.title,
    required this.description,
    required this.startedAt,
    required this.likes,
    required this.liked,
    required this.listenerCount,
    this.roomId,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString();
    return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toLocal();
    final s = v.toString();
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  factory LiveChatStatus.fromJson(Map<String, dynamic> json) {
    return LiveChatStatus(
      isLive:
          json['is_live'] == true || json['status']?.toString() == 'started',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startedAt: _toDate(json['started_at']),
      likes: _toInt(json['likes']),
      liked: json['liked'] == true,
      listenerCount: _toInt(json['listener_count']),
      roomId: json['room_id'] == null ? null : _toInt(json['room_id']),
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
    int? roomId,
  }) {
    return LiveChatStatus(
      isLive: isLive ?? this.isLive,
      title: title ?? this.title,
      description: description ?? this.description,
      startedAt: startedAt ?? this.startedAt,
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,
      listenerCount: listenerCount ?? this.listenerCount,
      roomId: roomId ?? this.roomId,
    );
  }
}
