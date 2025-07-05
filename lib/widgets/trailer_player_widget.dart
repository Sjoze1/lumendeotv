import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:html' as html;

import '../widgets/end_screen_widget.dart';

class TrailerPlayerWidget extends StatefulWidget {
  final String trailerUrl;
  final VoidCallback onWatchFull;
  final VoidCallback onExit;

  const TrailerPlayerWidget({
    super.key,
    required this.trailerUrl,
    required this.onWatchFull,
    required this.onExit,
  });

  @override
  State<TrailerPlayerWidget> createState() => _TrailerPlayerWidgetState();
}

class _TrailerPlayerWidgetState extends State<TrailerPlayerWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _showEndScreen = false;
  bool _isInitializing = true;
  bool _enteredFullscreen = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _enterFullscreen();
    _initializePlayer(widget.trailerUrl);
  }

  Future<void> _initializePlayer(String url) async {
    _videoController = VideoPlayerController.network(
      url,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    await _videoController.initialize();
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

    _videoController.addListener(() {
      if (_videoController.value.isPlaying && !_enteredFullscreen && kIsWeb) {
        _enteredFullscreen = true;

        // Attempt to request fullscreen
        final doc = html.document.documentElement;
        if (doc?.requestFullscreen != null) {
          doc!.requestFullscreen();
        }

        // Attempt to lock to landscape
        try {
          html.window.screen?.orientation
              ?.lock('landscape')
              .then((_) {})
              .catchError((_) {});
        } catch (_) {
          // iOS/Safari will silently fail
        }
      }

      if (_videoController.value.position >= _videoController.value.duration &&
          !_videoController.value.isPlaying &&
          mounted &&
          !_showEndScreen) {
        setState(() => _showEndScreen = true);
      }
    });

    setState(() => _isInitializing = false);
  }

  void _enterFullscreen() {
    final doc = html.document.documentElement;
    if (doc?.requestFullscreen != null) {
      doc!.requestFullscreen();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) html.document.exitFullscreen();
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final isMobileWeb = kIsWeb && sz.width < 600;

    Widget content;

    if (_isInitializing || _chewieController == null) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_showEndScreen) {
      content = EndScreenWidget(onWatchFull: widget.onWatchFull);
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          content,
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: widget.onExit,
            ),
          ),
        ],
      ),
    );
  }
}
