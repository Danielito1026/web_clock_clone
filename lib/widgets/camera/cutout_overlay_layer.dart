import 'package:web_clock_clone/widgets/detection_styles/detection_style.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Cutout overlay layer — dims outside the face frame + draws the border
// ---------------------------------------------------------------------------

class CutoutOverlayLayer extends StatelessWidget {
  final DetectionStyle style;

  const CutoutOverlayLayer({super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CutoutPainter(style: style),
      child: const SizedBox.expand(),
    );
  }
}

class _CutoutPainter extends CustomPainter {
  final DetectionStyle style;

  const _CutoutPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final shape = style.cutoutShape;

    final cutoutWidth =
        size.width *
        (shape is OvalCutout
            ? shape.widthFactor
            : (shape as RectCutout).widthFactor);
    final cutoutHeight =
        size.height *
        (shape is OvalCutout
            ? shape.heightFactor
            : (shape as RectCutout).heightFactor);

    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: cutoutWidth,
      height: cutoutHeight,
    );

    final cutoutPath = _buildCutoutPath(shape, cutoutRect);

    // --- Dim overlay with transparent cutout hole ---
    //
    // Previously used Path.combine(PathOperation.difference, ...) which works
    // in debug (software renderer) but breaks in release builds on Android
    // where Skia/Impeller handles PathOperation.difference incorrectly on the
    // GPU — producing an opaque white/black fill instead of a transparent hole.
    //
    // Fix: use saveLayer + BlendMode.clear to punch the hole instead.
    // saveLayer isolates this drawing to its own compositing layer so
    // BlendMode.clear only erases within that layer, not the camera preview
    // behind it. This is renderer-agnostic and works in both debug and release.
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.saveLayer(fullRect, Paint());

    // 1. Fill the entire layer with the dim overlay color
    canvas.drawRect(fullRect, Paint()..color = style.cameraOverlayColor);

    // 2. Punch out the cutout area using BlendMode.clear
    //    This erases pixels within the cutout to fully transparent,
    //    revealing the camera preview behind the layer.
    canvas.drawPath(cutoutPath, Paint()..blendMode = BlendMode.clear);

    canvas.restore();

    // --- Frame border (drawn after restore so it sits above the dim layer) ---
    canvas.drawPath(
      cutoutPath,
      Paint()
        ..color = style.frameBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.frameBorderWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _buildCutoutPath(CutoutShape shape, Rect rect) {
    return switch (shape) {
      OvalCutout() => Path()..addOval(rect),
      RectCutout(borderRadius: final r) =>
        Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r))),
    };
  }

  @override
  bool shouldRepaint(_CutoutPainter oldDelegate) =>
      oldDelegate.style.cutoutShape != style.cutoutShape ||
      oldDelegate.style.cameraOverlayColor != style.cameraOverlayColor ||
      oldDelegate.style.frameBorderColor != style.frameBorderColor;
}
