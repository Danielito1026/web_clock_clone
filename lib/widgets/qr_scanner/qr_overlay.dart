import 'package:flutter/material.dart';
import 'package:web_clock_clone/widgets/camera/cutout_overlay_layer.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_style.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_theme.dart';
import 'package:web_clock_clone/widgets/qr_scanner/gallery_button.dart';
import 'package:web_clock_clone/widgets/qr_scanner/scan_line.dart';
import 'package:web_clock_clone/widgets/qr_scanner/timeout_overlay.dart';

// ---------------------------------------------------------------------------
// Overlay — cutout + scan line + gallery button + status message
// ---------------------------------------------------------------------------

class QrOverlay extends StatefulWidget {
  final DetectionStyle style;
  final ValueNotifier<String?> statusMessage;
  final bool isLoading;
  final bool timedOut;
  final VoidCallback onPickFromGallery;
  final VoidCallback onRetry;

  const QrOverlay({
    super.key,
    required this.style,
    required this.statusMessage,
    required this.isLoading,
    required this.timedOut,
    required this.onPickFromGallery,
    required this.onRetry,
  });

  @override
  State<QrOverlay> createState() => QrOverlayState();
}

class QrOverlayState extends State<QrOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLine;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanLine = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen timeout state — replaces the normal scanner overlay
    if (widget.timedOut) {
      return TimeoutOverlay(
        style: widget.style,
        onRetry: widget.onRetry,
        onPickFromGallery: widget.onPickFromGallery,
      );
    }

    return Stack(
      children: [
        // Dim layer + rect cutout border
        CutoutOverlayLayer(style: widget.style),

        // Animated scan line (paused while processing a gallery image)
        if (!widget.isLoading)
          AnimatedBuilder(
            animation: _scanLine,
            builder: (context, _) =>
                ScanLine(style: widget.style, progress: _scanLine.value),
          ),

        // Loading spinner shown while a gallery image is being processed
        if (widget.isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: DetectionColors.crimsonLight,
              strokeWidth: 2.5,
            ),
          ),

        // Hint label + transient status message
        Positioned(
          bottom: 130,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<String?>(
            valueListenable: widget.statusMessage,
            builder: (_, message, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: message != null
                    ? _StatusBanner(key: ValueKey(message), message: message)
                    : _HintLabel(
                        style: widget.style,
                        key: const ValueKey('hint'),
                      ),
              );
            },
          ),
        ),

        // Gallery button
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GalleryButton(
              style: widget.style,
              isLoading: widget.isLoading,
              onTap: widget.onPickFromGallery,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay sub-widgets
// ---------------------------------------------------------------------------

class _HintLabel extends StatelessWidget {
  final DetectionStyle style;

  const _HintLabel({super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: style.overlayPanelColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: style.overlayPanelBorderColor),
        ),
        child: Text(
          'Point your camera at a QR code',
          style: style.subtitleTextStyle,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;

  const _StatusBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DetectionColors.navyMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DetectionColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: DetectionColors.whiteMid,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: DetectionColors.whiteHigh,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
