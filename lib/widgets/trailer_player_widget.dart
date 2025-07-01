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
    if (kIsWeb) _enterBrowserFullscreen();
    _initializePlayer(widget.trailerUrl);
  }

  Future<void> _initializePlayer(String url) async {
    _videoController = VideoPlayerController.network(
      url,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await _videoController.initialize();
      _createChewieController();
      _videoController.addListener(_checkTrailerEnd);
      await _videoController.play();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Video player failed to initialize: $e');
    }
  }

  void _createChewieController() {
    _chewieController?.dispose();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: false,
      allowPlaybackSpeedChanging: true,
      showControls: true,
      aspectRatio: _videoController.value.aspectRatio > 0
          ? _videoController.value.aspectRatio
          : 16 / 9,
    );
  }

  void _checkTrailerEnd() {
    if (_videoController.value.position >= _videoController.value.duration &&
        !_videoController.value.isPlaying &&
        mounted &&
        !_showEndScreen) {
      setState(() {
        _showEndScreen = true;
      });
    }
  }

  void _enterBrowserFullscreen() {
    final html.Element? docElm = html.document.documentElement;
    if (docElm != null) {
      docElm.requestFullscreen();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      html.document.exitFullscreen();
    }
    _videoController.removeListener(_checkTrailerEnd);
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    Widget videoContent = _isInitializing ||
            !_videoController.value.isInitialized ||
            _chewieController == null
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: SizedBox.expand(
                  child: Chewie(controller: _chewieController!),
                ),
              ),
              if (_showEndScreen)
                EndScreenWidget(
                  onWatchFull: widget.onWatchFull,
                ),
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
      videoContent = RotatedBox(
        quarterTurns: 1,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: videoContent,
            ),
          ),
        ),
      );
    }

    return Scaffold(body: videoContent);
  }
}
