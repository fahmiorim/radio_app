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

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  factory LiveChatStatus.fromJson(Map<String, dynamic> json) {
    DateTime? started;
    final raw = json['started_at'];
    if (raw is String && raw.isNotEmpty) {
      try {
        started = DateTime.parse(raw).toLocal(); // ISO + offset: aman
      } catch (_) {}
    }

    return LiveChatStatus(
      isLive: json['is_live'] == true,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startedAt: started,
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
