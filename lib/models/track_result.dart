class TrackResult {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final int durationSeconds;

  TrackResult({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.durationSeconds,
  });

  factory TrackResult.fromJson(Map<String, dynamic> json) {
    return TrackResult(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() {
    return 'TrackResult(videoId: $videoId, title: $title, artist: $artist, duration: $durationSeconds)';
  }
}
