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
      allowFullScreen: false,
      showControls: true,
      aspectRatio: _videoController.value.aspectRatio,
    );
    _videoController.addListener(() {
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
    if (doc?.requestFullscreen != null) doc!.requestFullscreen();
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
    final isLandscape = sz.width > sz.height;

    Widget player = _isInitializing || _chewieController == null
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            fit: StackFit.expand,
            children: [
              Chewie(controller: _chewieController!),
              if (_showEndScreen)
                EndScreenWidget(onWatchFull: widget.onWatchFull),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: widget.onExit,
                ),
              ),
            ],
          );

    if (kIsWeb && !isLandscape) {
      player = RotatedBox(
        quarterTurns: 1,
        child: SizedBox(
          width: sz.height,
          height: sz.width,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: sz.width,
              height: sz.height,
              child: player,
            ),
          ),
        ),
      );
    }

    return Scaffold(body: player);
  }
}
