import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _FullVideoPlayerWidgetState extends State<FullVideoPlayerWidget> with WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  bool _showExit = false;

  final String _resumeKey = 'full_video_resume_position';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer(widget.fullVideoUrl);
  }

  Future<void> _initializePlayer(String url) async {
    _videoController = VideoPlayerController.network(
      url,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await _videoController.initialize();

      // Resume playback from saved position
      final prefs = await SharedPreferences.getInstance();
      final savedMillis = prefs.getInt(_resumeKey) ?? 0;
      final savedPosition = Duration(milliseconds: savedMillis);

      if (savedPosition < _videoController.value.duration) {
        await _videoController.seekTo(savedPosition);
      }

      _createChewieController();

      _videoController.addListener(_checkVideoEnd);
      await _videoController.play();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Full video player failed to initialize: $e');
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

  void _checkVideoEnd() {
    final pos = _videoController.value.position;
    final dur = _videoController.value.duration;

    if (pos >= dur && !_showExit && mounted) {
      setState(() {
        _showExit = true;
      });
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _savePlaybackPosition(); // Just in case
    _videoController.removeListener(_checkVideoEnd);
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _savePlaybackPosition();
    }
    if (state == AppLifecycleState.detached || state == AppLifecycleState.hidden) {
      _savePlaybackPosition();
    }
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
              if (_showExit)
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () async {
                      await _clearPlaybackPosition();
                      widget.onExit();
                    },
                  ),
                ),
            ],
          );

    if (kIsWeb && !isLandscape) {
      // Rotate video 90 degrees on web if in portrait mode
      videoContent = Center(
        child: Transform.rotate(
          angle: 3.14159 / 2, // 90 degrees in radians
          child: SizedBox(
            width: size.height,
            height: size.width,
            child: videoContent,
          ),
        ),
      );
    }

    return Scaffold(body: videoContent);
  }
}
