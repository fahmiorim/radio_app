class NowPlayingInfo {
  final String title;
  final String artist;
  final String artUrl;

  const NowPlayingInfo({
    required this.title,
    required this.artist,
    required this.artUrl,
  });

  factory NowPlayingInfo.fromJson(Map<String, dynamic> json) {
    final song = (json['now_playing'] ?? const {})['song'] ?? const {};
    return NowPlayingInfo(
      title: song['title']?.toString() ?? '',
      artist: song['artist']?.toString() ?? '',
      artUrl: song['art']?.toString() ?? '',
    );
  }
}
