import 'package:flutter/material.dart';

class EndScreenWidget extends StatelessWidget {
  final VoidCallback onWatchFull;

  const EndScreenWidget({
    super.key,
    required this.onWatchFull,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Centered 16:9 background image that preserves aspect ratio
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'lib/assets/Paymentendscreenlumendeo.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Centered click link
          Align(
            alignment: const Alignment(0.05, 0.1),
            child: TextButton(
              onPressed: onWatchFull,
              child: const Text(
                'Click here',
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 22,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          // Top-left logo
          Positioned(
            top: 16,
            left: 16,
            child: Image.asset(
              'lib/assets/lumendeotv-icon.jpg',
              width: 80,
              height: 80,
            ),
          ),
        ],
      ),
    );
  }
}
