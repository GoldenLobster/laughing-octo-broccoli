class StreamInfo {
  final String? url;
  final String? mimeType;
  final int? bitrate;
  final int? expiresAt;
  final String? error;

  StreamInfo({
    this.url,
    this.mimeType,
    this.bitrate,
    this.expiresAt,
    this.error,
  });

  factory StreamInfo.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error') && json['error'] != null) {
      return StreamInfo(error: json['error'] as String);
    }
    return StreamInfo(
      url: json['url'] as String?,
      mimeType: json['mimeType'] as String?,
      bitrate: (json['bitrate'] as num?)?.toInt(),
      expiresAt: (json['expiresAt'] as num?)?.toInt(),
    );
  }

  @override
  String toString() {
    return 'StreamInfo(url: $url, error: $error)';
  }
}
