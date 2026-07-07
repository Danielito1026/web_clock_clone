import 'package:flutter/material.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_style.dart';

class ScanLine extends StatelessWidget {
  final DetectionStyle style;
  final double progress;

  const ScanLine({super.key, required this.style, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shape = style.cutoutShape as RectCutout;
        final cutoutW = constraints.maxWidth * shape.widthFactor;
        final cutoutH = constraints.maxHeight * shape.heightFactor;
        final left = (constraints.maxWidth - cutoutW) / 2;
        final cutoutTop = constraints.maxHeight * 0.42 - cutoutH / 2;
        final lineY = cutoutTop + cutoutH * progress;

        return Stack(
          children: [
            Positioned(
              top: lineY,
              left: left + 4,
              child: Container(
                width: cutoutW - 8,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      style.frameBorderColor.withValues(alpha: 0.8),
                      style.frameBorderColor,
                      style.frameBorderColor.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}