import 'package:flutter/material.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_style.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_theme.dart';

class GalleryButton extends StatelessWidget {
  final DetectionStyle style;
  final bool isLoading;
  final VoidCallback onTap;

  const GalleryButton({
    super.key,
    required this.style,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: style.overlayPanelColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: style.overlayPanelBorderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: DetectionColors.whiteMid,
              ),
              const SizedBox(width: 8),
              Text(
                'Upload from Gallery',
                style: style.subtitleTextStyle.copyWith(
                  color: DetectionColors.whiteHigh,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}