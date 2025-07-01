import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:html' as html;
import 'package:flutter/services.dart';

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
    );

    _videoController.addListener(() {
      if (_videoController.value.position >= _videoController.value.duration &&
          !_videoController.value.isPlaying &&
          mounted &&
          !_showEndScreen) {
        setState(() => _showEndScreen = true);
        _exitFullscreenAndUnlockOrientation();
      }
    });

    if (kIsWeb) {
      html.document.onFullscreenChange.listen((event) {
        if (html.document.fullscreenElement != null) {
          _lockOrientationToLandscape();
        } else {
          _unlockOrientation();
        }
      });
    }

    setState(() => _isInitializing = false);
  }

  void _lockOrientationToLandscape() {
    if (kIsWeb) {
      try {
        html.window.screen?.orientation?.lock('landscape').catchError((e) {
          print('Error locking orientation to landscape: $e');
        });
      } catch (e) {
        print('Could not access screen orientation API: $e');
      }
    }
  }

  void _unlockOrientation() {
    if (kIsWeb) {
      try {
        html.window.screen?.orientation?.unlock();
      } catch (e) {
        print('Could not access screen orientation API for unlock: $e');
      }
    }
  }


  void _exitFullscreenAndUnlockOrientation() {
    if (kIsWeb) {
      try {
        html.document.exitFullscreen();
        _unlockOrientation();
      } catch (error) {
        print('Error exiting fullscreen: $error');
      }
    }
  }

  @override
  void dispose() {
    _exitFullscreenAndUnlockOrientation();
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isInitializing || _chewieController == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  child: Chewie(controller: _chewieController!),
                  onTap: () {},
                ),
                if (_showEndScreen)
                  EndScreenWidget(onWatchFull: widget.onWatchFull),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () {
                      _exitFullscreenAndUnlockOrientation();
                      widget.onExit();
                    },
                  ),
                ),
              ],
            ),
    );
  }
}