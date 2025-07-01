import 'package:flutter/material.dart';

class UploadProgressWidget extends StatelessWidget {
  final double progress; // from 0.0 to 1.0
  final VoidCallback onCancel;

  const UploadProgressWidget({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)), // gold
                    backgroundColor: Colors.white10,
                  ),
                ),
                const Icon(
                  Icons.upload_rounded,
                  size: 40,
                  color: Color(0xFFFFD700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel, color: Colors.black),
                label: const Text(
                  'Cancel Upload',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
