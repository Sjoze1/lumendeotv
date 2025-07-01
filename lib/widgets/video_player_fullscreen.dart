import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/video_model.dart';
import '../pages/payment.dart'; 
import 'full_video_player_widget.dart';
import 'trailer_player_widget.dart';

class FullScreenTrailerPlayer extends StatefulWidget {
  final VideoItem video;
  const FullScreenTrailerPlayer({super.key, required this.video});

  @override
  State<FullScreenTrailerPlayer> createState() => _FullScreenTrailerPlayerState();
}

class _FullScreenTrailerPlayerState extends State<FullScreenTrailerPlayer> {
  bool _isTrailer = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  Future<void> _playFullVideo() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MpesaPaymentPage(
          onSuccess: () => Navigator.pop(context, true),
          onCancel: () => Navigator.pop(context, false),
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _isTrailer = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment was not completed.')),
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isTrailer
        ? TrailerPlayerWidget(
            trailerUrl: widget.video.trailerUrl,
            onWatchFull: _playFullVideo,
            onExit: () => Navigator.pop(context),
          )
        : FullVideoPlayerWidget(
            fullVideoUrl: widget.video.fullVideoUrl,
            onExit: () => Navigator.pop(context),
          );
  }
}
