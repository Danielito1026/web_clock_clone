import 'package:flutter/material.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_style.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_theme.dart';

// ---------------------------------------------------------------------------
// Timeout overlay — shown when scanTimeout elapses with no result
// ---------------------------------------------------------------------------

class TimeoutOverlay extends StatelessWidget {
  final DetectionStyle style;
  final VoidCallback onRetry;
  final VoidCallback onPickFromGallery;

  const TimeoutOverlay({
    super.key,
    required this.style,
    required this.onRetry,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DetectionColors.cameraOverlay,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: DetectionColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DetectionColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DetectionColors.crimson.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_off_outlined,
                  color: DetectionColors.crimsonLight,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scanner timed out',
                style: DetectionTextStyles.dialogTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'No QR code was detected in time.\nYou can try scanning again or upload an image from your gallery.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Retry button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DetectionColors.crimson,
                    foregroundColor: DetectionColors.whiteHigh,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Gallery fallback
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPickFromGallery,
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    size: 18,
                    color: DetectionColors.crimsonLight,
                  ),
                  label: const Text(
                    'Upload from Gallery',
                    style: TextStyle(color: DetectionColors.crimsonLight),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: DetectionColors.crimson),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
