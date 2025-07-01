import 'package:flutter/material.dart';
import '../widgets/video_player_fullscreen.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add floating action button here
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFD700), // Gold color for consistency
        onPressed: () {
          Navigator.pushNamed(context, '/upload');
        },
        tooltip: 'Upload Video',
        child: const Icon(Icons.upload_file),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/assets/plainlumendeobackground.jpg',
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 40,
            left: 25,
            child: Image.asset(
              'lib/assets/lumendeotv-icon.jpg',
              width: 110,
              height: 110,
            ),
          ),
          // Removed the old Positioned IconButton here

          FutureBuilder<VideoItem>(
            future: fetchVideoFromBackend(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No video available.'));
              }

              final video = snapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.25,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenTrailerPlayer(video: video),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.75),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  video.thumbnailUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Icon(
                                Icons.play_circle_fill,
                                size: 64,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              video.description,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
