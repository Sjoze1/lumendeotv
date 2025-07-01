import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

const String baseUrl = 'https://lumendeotv-project-backend.onrender.com';

Future<VideoItem> fetchVideoFromBackend() async {
  final response = await http.get(Uri.parse('$baseUrl/api/videos'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);

    if (jsonList.isEmpty) {
      throw Exception('No videos found');
    }

    // Backend returns signed URLs, so just parse and return directly
    final video = VideoItem.fromJson(jsonList[0]);
    return video;
  } else {
    throw Exception('Failed to load video');
  }
}
