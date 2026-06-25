import 'package:flutter/material.dart';

class HalfCard extends StatelessWidget {
  const HalfCard({
    super.key,
    required this.width,
    required this.height,
    required this.digit,
    required this.isTop,
    required this.fontSize,
    this.shadow = false,
    this.digitColor,
    this.backgroundColor,
    this.showBorder,
    this.borderWidth,
    this.borderColor,
    required this.borderRadius,
    this.hingeWidth,
    this.hingeLength,
    this.hingeColor,
  });

  final double width;
  final double height;
  final String digit;
  final bool isTop;
  final double fontSize;
  final bool shadow;
  final Color? digitColor;
  final Color? backgroundColor;
  final bool? showBorder;
  final double? borderWidth;
  final Color? borderColor;
  final BorderRadius borderRadius;
  final double? hingeWidth;
  final double? hingeLength;
  final Color? hingeColor;

  double _getResponsiveHeight() {
    // Base height for small fonts
    if (fontSize <= 28) return 0.6;
    // Medium fonts
    if (fontSize <= 44) return 0.55;
    // Large fonts
    return 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderWidth =
        (showBorder == true ? borderWidth : 0.0) ?? 0.0;
    final effectiveBorderColor =
        borderColor ?? Colors.black.withValues(alpha: 0.3);

    final radius = borderRadius.topLeft;

    return ClipRRect(
      clipBehavior: Clip.antiAlias ,
      borderRadius: isTop
          ? BorderRadius.only(topLeft: radius, topRight: radius)
          : BorderRadius.only(bottomLeft: radius, bottomRight: radius),
      child: Container(
        width: width,
        height: height / 2,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF1E1E26),
          border: Border(
            bottom: isTop && showBorder == true
                ? BorderSide(
                    color: effectiveBorderColor,
                    width: effectiveBorderWidth,
                  )
                : BorderSide.none,
            top: !isTop && showBorder == true
                ? BorderSide(
                    color: effectiveBorderColor,
                    width: effectiveBorderWidth,
                  )
                : BorderSide.none,
          ),
        ),
        child: Stack(
          children: [
            // Subtle gloss on top card
            if (isTop)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.08,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Hinge effect (horizontal line)
            if (hingeWidth != null && hingeWidth! > 0 && !isTop && shadow)
              Positioned(
                top: -2,
                left: 0,
                right: 0,
                child: Container(
                  height: hingeLength ?? 3,
                  color: hingeColor ?? Colors.black.withValues(alpha: 0.3),
                ),
              ),

            // The digit – clipped to show only top or bottom half
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(0, isTop ? height * 0.25 : -height * 0.25),
                child: Text(
                  digit,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: digitColor ?? const Color(0xFFF0F0F5),
                    height: _getResponsiveHeight(),
                  ),
                ),
              ),
            ),

            // Shadow overlay during flip
            if (shadow) Container(color: Colors.black.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }
}
