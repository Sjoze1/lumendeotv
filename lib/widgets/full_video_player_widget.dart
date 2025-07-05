import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;

class FullVideoPlayerWidget extends StatefulWidget {
  final String fullVideoUrl;
  final VoidCallback onExit;

  const FullVideoPlayerWidget({
    super.key,
    required this.fullVideoUrl,
    required this.onExit,
  });

  @override
  State<FullVideoPlayerWidget> createState() => _FullVideoPlayerWidgetState();
}

class _FullVideoPlayerWidgetState extends State<FullVideoPlayerWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  bool _enteredFullscreen = false;

  final String _resumeKey = 'full_video_resume_position';

  @override
  void initState() {
    super.initState();
    _initializePlayer(widget.fullVideoUrl);
  }

  Future<void> _initializePlayer(String url) async {
    _videoController = VideoPlayerController.network(
      url,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    await _videoController.initialize();

    final prefs = await SharedPreferences.getInstance();
    final savedMillis = prefs.getInt(_resumeKey) ?? 0;
    final savedPosition = Duration(milliseconds: savedMillis);

    await _videoController.play(); // 🔄 Start playing immediately
    if (savedPosition < _videoController.value.duration) {
      await _videoController.seekTo(savedPosition); // 🔄 Then seek
    }

    _chewieController?.dispose();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      showControls: true,
      aspectRatio: _videoController.value.aspectRatio,
      allowPlaybackSpeedChanging: true,
    );

    _videoController.addListener(() async {
      if (_videoController.value.isPlaying && !_enteredFullscreen && kIsWeb) {
        _enteredFullscreen = true;

        final doc = html.document.documentElement;
        if (doc?.requestFullscreen != null) {
          await doc!.requestFullscreen();
        }

        try {
          await html.window.screen?.orientation?.lock('landscape');
        } catch (_) {
          // iOS/Safari silently fails
        }
      }
    });

    setState(() => _isInitializing = false);
  }

  Future<void> _savePlaybackPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMillis = _videoController.value.position.inMilliseconds;
    await prefs.setInt(_resumeKey, currentMillis);
  }

  Future<void> _clearPlaybackPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_resumeKey);
  }

  @override
  void dispose() {
    _savePlaybackPosition();
    _videoController.dispose();
    _chewieController?.dispose();
    if (kIsWeb) {
      html.document.exitFullscreen();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final isMobileWeb = kIsWeb && sz.width < 600;

    Widget content;

    if (_isInitializing || _chewieController == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: isMobileWeb
                ? Transform.scale(
                    scale: 0.85,
                    child: Chewie(controller: _chewieController!),
                  )
                : Chewie(controller: _chewieController!),
          ),
        ),
      );
    }

    // Fallback rotation for devices where orientation lock fails
    if (kIsWeb && sz.height > sz.width) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: RotatedBox(
          quarterTurns: 1,
          child: SizedBox(
            width: sz.height,
            height: sz.width,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: sz.width,
                height: sz.height,
                child: Stack(
                  children: [
                    content,
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () async {
                          await _clearPlaybackPosition();
                          widget.onExit();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          content,
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () async {
                await _clearPlaybackPosition();
                widget.onExit();
              },
            ),
          ),
        ],
      ),
    );
  }
}

