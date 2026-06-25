// qr_scanner_widget.dart
// Location: lib/shared/widgets/qr_scanner_widget.dart
//
// QR code scanner widget built on top of CameraInputStream.
// Uses google_mlkit_barcode_scanning to decode QR codes from the camera feed.
//
// Responsibilities:
//   - Wire CameraInputStream (back camera) to BarcodeScanner
//   - Gate frames with _isProcessing to avoid overlapping ML Kit calls
//   - Emit the first decoded barcode via [onBarcodeDetected]
//   - Lock after first detection so the caller can navigate away cleanly
//   - Draw the QR frame cutout overlay via CutoutOverlayLayer
//   - Allow picking a QR code image from the gallery via image_picker
//
// This widget does NOT:
//   - Navigate anywhere — that's the caller's job (QrScannerPage)
//   - Know what a URL, vCard, or WiFi payload means — it just emits the raw value
//
// ---------------------------------------------------------------------------
// Usage:
//
//   QrScannerWidget(
//     onBarcodeDetected: (barcode) {
//       Navigator.push(context, MaterialPageRoute(
//         builder: (_) => QrResultPage(barcode: barcode),
//       ));
//     },
//   )
// ---------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:web_clock_clone/widgets/camera/camera_input_stream.dart';
import 'package:web_clock_clone/widgets/camera/cutout_overlay_layer.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_style.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_theme.dart';
import 'package:image_picker/image_picker.dart';

class QrScannerWidget extends StatefulWidget {
  /// Called once when a QR code (or other barcode) is successfully decoded,
  /// whether from the live camera feed or a picked gallery image.
  final void Function(String barcode) onBarcodeDetected;

  /// Optional style. Defaults to a rect cutout variant of DetectionStyle.defaults().
  final DetectionStyle? style;

  /// Optional callback if the camera fails to initialize.
  final VoidCallback? onInitFailure;

  const QrScannerWidget({
    super.key,
    required this.onBarcodeDetected,
    this.style,
    this.onInitFailure,
  });

  @override
  State<QrScannerWidget> createState() => QrScannerWidgetState();
}

class QrScannerWidgetState extends State<QrScannerWidget> {
  final BarcodeScanner _scanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode],
  );
  final ImagePicker _picker = ImagePicker();

  bool _isProcessing = false;
  bool _locked = false; // true after first successful scan
  bool _isPickingOrProcessingImage = false;

  // Drives the transient status message shown in the overlay
  // (e.g. "No QR code found in image", "Processing image…").
  // Null = no message shown.
  final ValueNotifier<String?> _statusMessage = ValueNotifier(null);

  final _cameraKey = GlobalKey<CameraInputStreamState>();

  DetectionStyle get _style =>
      widget.style ??
      DetectionStyle.defaults().copyWith(
        // Square-ish rect cutout is more natural for QR codes
        cutoutShape: const RectCutout(
          widthFactor: 0.75,
          heightFactor: 0.40,
          borderRadius: CutoutDefaults.rectBorderRadius,
        ),
        frameBorderColor: DetectionColors.crimson,
        frameBorderWidth: 3.0,
      );

  /// Unlocks the scanner so it processes frames again.
  /// Call this if the result page is dismissed and you want to re-scan.
  void reset() {
    setState(() {
      _locked = false;
      _isPickingOrProcessingImage = false;
    });
    _statusMessage.value = null;
  }

  @override
  void dispose() {
    _scanner.close();
    _statusMessage.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Live camera frame processing
  // ---------------------------------------------------------------------------

  Future<void> _processFrame(InputImage inputImage) async {
    if (_isProcessing || _locked || _isPickingOrProcessingImage) return;
    _isProcessing = true;

    try {
      final barcodes = await _scanner.processImage(inputImage);
      if (_locked) return; // double-check after async gap

      if (barcodes.isNotEmpty) {
        _locked = true;
        widget.onBarcodeDetected(barcodes.first.rawValue!);
      }
    } catch (_) {
      // Swallow per-frame errors — camera keeps running
    } finally {
      _isProcessing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Gallery pick + process
  // ---------------------------------------------------------------------------

  Future<void> _pickFromGallery() async {
    if (_isPickingOrProcessingImage || _locked) return;

    setState(() => _isPickingOrProcessingImage = true);
    _statusMessage.value = null;

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);

      if (picked == null) {
        // User cancelled — nothing to do
        return;
      }

      _statusMessage.value = 'Processing image…';

      final inputImage = InputImage.fromFilePath(picked.path);
      final barcodes = await _scanner.processImage(inputImage);

      if (!mounted) return;

      if (barcodes.isEmpty) {
        _statusMessage.value = 'No QR code found in that image.';
        // Auto-clear the message after 3 seconds
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _statusMessage.value = null;
        return;
      }

      _locked = true;
      _statusMessage.value = null;
      widget.onBarcodeDetected(barcodes.first.rawValue!);
    } catch (_) {
      if (mounted) {
        _statusMessage.value = 'Could not read the image. Try another.';
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _statusMessage.value = null;
      }
    } finally {
      if (mounted) setState(() => _isPickingOrProcessingImage = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CameraInputStream(
      key: _cameraKey,
      lensDirection: CameraLensDirection.back,
      onImage: _processFrame,
      onInitFailure: widget.onInitFailure,
      overlayBuilder: (ctx) => _QrOverlay(
        style: _style,
        statusMessage: _statusMessage,
        isLoading: _isPickingOrProcessingImage,
        cameraKey: _cameraKey,
        onPickFromGallery: _pickFromGallery,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay — cutout + scan line + gallery button + status message
// ---------------------------------------------------------------------------

class _QrOverlay extends StatefulWidget {
  final DetectionStyle style;
  final ValueNotifier<String?> statusMessage;
  final bool isLoading;
  final VoidCallback onPickFromGallery;
  final GlobalKey<CameraInputStreamState> cameraKey;

  const _QrOverlay({
    required this.style,
    required this.statusMessage,
    required this.isLoading,
    required this.onPickFromGallery,
    required this.cameraKey
  });

  @override
  State<_QrOverlay> createState() => _QrOverlayState();
}

class _QrOverlayState extends State<_QrOverlay>
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
    return Stack(
      children: [
        // Dim layer + rect cutout border
        CutoutOverlayLayer(style: widget.style),

        // Animated scan line (paused while processing a gallery image)
        if (!widget.isLoading)
          AnimatedBuilder(
            animation: _scanLine,
            builder: (context, _) =>
                _ScanLine(style: widget.style, progress: _scanLine.value),
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
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: DetectionColors.whiteHigh,
                  ),
                  onPressed: () => widget.cameraKey.currentState?.switchCamera(),
                ),
                _GalleryButton(
                  style: widget.style,
                  isLoading: widget.isLoading,
                  onTap: widget.onPickFromGallery,
                ),
              ],
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

class _GalleryButton extends StatelessWidget {
  final DetectionStyle style;
  final bool isLoading;
  final VoidCallback onTap;

  const _GalleryButton({
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
                color: DetectionColors.whiteHigh,
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

// ---------------------------------------------------------------------------
// Scan line
// ---------------------------------------------------------------------------

class _ScanLine extends StatelessWidget {
  final DetectionStyle style;
  final double progress; // 0.0 → 1.0 within the cutout height

  const _ScanLine({required this.style, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return const SizedBox.shrink();
        }

        final shape = style.cutoutShape;
        final widthFactor = shape is RectCutout
            ? shape.widthFactor
            : shape is OvalCutout
            ? shape.widthFactor
            : 0.7;
        final heightFactor = shape is RectCutout
            ? shape.heightFactor
            : shape is OvalCutout
            ? shape.heightFactor
            : 0.42;

        final cutoutW = constraints.maxWidth * widthFactor;
        final cutoutH = constraints.maxHeight * heightFactor;
        final left = (constraints.maxWidth - cutoutW) / 2;
        // Mirror the vertical offset used in the painter (0.42 of screen height)
        final cutoutTop = constraints.maxHeight * 0.42 - cutoutH / 2;
        final lineY = cutoutTop + cutoutH * progress;

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              Positioned(
                top: lineY,
                left: left + 4,
                child: Container(
                  width: math.max(0, cutoutW - 8),
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
          ),
        );
      },
    );
  }
}
