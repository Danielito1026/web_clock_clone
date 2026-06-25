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

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:web_clock_clone/widgets/camera/camera_input_stream.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_style.dart';
import 'package:web_clock_clone/widgets/detection_styles/detection_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_clock_clone/widgets/qr_scanner/qr_overlay.dart';

class QrScannerWidget extends StatefulWidget {
  /// Called once when a QR code (or other barcode) is successfully decoded,
  /// whether from the live camera feed or a picked gallery image.
  final void Function(String barcode) onBarcodeDetected;

  /// How long to keep the scanner active with no successful scan before
  /// stopping the image stream and calling [onTimeout].
  /// Defaults to 30 seconds. The timer resets when [reset] is called.
  /// Gallery picks do not count against the timeout — the timer is paused
  /// while the gallery flow is active.
  final Duration scanTimeout;

  /// Called when [scanTimeout] elapses with no successful scan.
  /// The scanner stops processing frames at this point — call [reset] on
  /// the widget's state key to restart it.
  /// If null, the scanner just goes silent after timeout with no callback.
  final VoidCallback? onTimeout;

  /// Optional style. Defaults to a rect cutout variant of DetectionStyle.defaults().
  final DetectionStyle? style;

  /// Optional callback if the camera fails to initialize.
  final VoidCallback? onInitFailure;

  const QrScannerWidget({
    super.key,
    required this.onBarcodeDetected,
    this.scanTimeout = const Duration(seconds: 30),
    this.onTimeout,
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
  bool _timedOut = false; // true after scanTimeout elapses with no result

  Timer? _timeoutTimer;

  // Drives the transient status message shown in the overlay
  // (e.g. "No QR code found in image", "Processing image…").
  // Null = no message shown.
  final ValueNotifier<String?> _statusMessage = ValueNotifier(null);

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

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // ---------------------------------------------------------------------------
  // Timeout timer
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(widget.scanTimeout, _onTimerFired);
  }

  void _cancelTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _onTimerFired() {
    if (!mounted || _locked) return;
    setState(() => _timedOut = true);
    // Stop the camera stream — the CameraInputStream key lets us reach its state
    _cameraKey.currentState?.pauseStream();
    widget.onTimeout?.call();
  }

  final GlobalKey<CameraInputStreamState> _cameraKey = GlobalKey();

  /// Unlocks the scanner so it processes frames again.
  /// Call this if the result page is dismissed and you want to re-scan.
  void reset() {
    _cancelTimer();
    setState(() {
      _locked = false;
      _timedOut = false;
      _isPickingOrProcessingImage = false;
    });
    _statusMessage.value = null;
    _cameraKey.currentState?.resumeStream();
    _startTimer();
  }

  @override
  void dispose() {
    _cancelTimer();
    _scanner.close();
    _statusMessage.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Live camera frame processing
  // ---------------------------------------------------------------------------

  Future<void> _processFrame(InputImage inputImage) async {
    if (_isProcessing || _locked || _isPickingOrProcessingImage || _timedOut) {
      return;
    }
    _isProcessing = true;

    try {
      final barcodes = await _scanner.processImage(inputImage);
      if (_locked) return; // double-check after async gap

      if (barcodes.isNotEmpty) {
        _cancelTimer();
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
    if (_isPickingOrProcessingImage || _locked || _timedOut) return;

    // Pause the timeout while the user is in the gallery picker — we don't
    // want the timer firing while the app is backgrounded for the gallery.
    _cancelTimer();
    setState(() => _isPickingOrProcessingImage = true);
    _statusMessage.value = null;

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);

      if (picked == null) {
        // User cancelled — restart the timeout from where it left off
        _startTimer();
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
        _startTimer();
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
      overlayBuilder: (ctx) => QrOverlay(
        style: _style,
        statusMessage: _statusMessage,
        isLoading: _isPickingOrProcessingImage,
        timedOut: _timedOut,
        onPickFromGallery: _pickFromGallery,
        onRetry: reset,
      ),
    );
  }
}
