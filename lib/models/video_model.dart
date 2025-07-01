class VideoItem {
  final int id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String trailerUrl;
  final String fullVideoUrl;

  VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.trailerUrl,
    required this.fullVideoUrl,
  });

factory VideoItem.fromJson(Map<String, dynamic> json) {
  String baseUrl = 'https://lumendeotv-project-backend.onrender.com';  // your backend base URL

  String fixUrl(String? url) {
    if (url == null) return '';
    if (url.startsWith('http')) {
      return url;
    }
    return baseUrl + url;
  }

  return VideoItem(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    thumbnailUrl: fixUrl(json['thumbnail_url']),
    trailerUrl: fixUrl(json['trailer_url']),
    fullVideoUrl: fixUrl(json['full_video_url']),
  );
}
}
