import 'package:flutter/material.dart';
import 'package:web_clock_clone/widgets/flipclock/flip_card.dart';

class FlipGroup extends StatelessWidget {
  final String value;
  final double digitSize;
  final double width;
  final double height;
  final AxisDirection flipDirection;
  final Curve? flipCurve;
  final Color? digitColor;
  final Color? backgroundColor;
  final bool? showBorder;
  final double? borderWidth;
  final Color? borderColor;
  final BorderRadius borderRadius;
  final double hingeWidth;
  final double? hingeLength;
  final Color? hingeColor;
  const FlipGroup({super.key,
  required this.value,
    required this.digitSize,
    required this.width,
    required this.height,
    required this.flipDirection,
    this.flipCurve,
    this.digitColor,
    this.backgroundColor,
    this.showBorder,
    this.borderWidth,
    this.borderColor,
    required this.borderRadius,
    required this.hingeWidth,
    this.hingeLength,
    this.hingeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlipCard(
          digit: value[0],
          digitSize: digitSize,
          width: width,
          height: height,
          flipDirection: flipDirection,
          flipCurve: flipCurve,
          digitColor: digitColor,
          backgroundColor: backgroundColor,
          showBorder: showBorder,
          borderWidth: borderWidth,
          borderColor: borderColor,
          borderRadius: borderRadius,
          hingeWidth: hingeWidth,
          hingeLength: hingeLength,
          hingeColor: hingeColor,
        ),
        const SizedBox(width: 3),
        FlipCard(
          digit: value[1],
          digitSize: digitSize,
          width: width,
          height: height,
          flipDirection: flipDirection,
          flipCurve: flipCurve,
          digitColor: digitColor,
          backgroundColor: backgroundColor,
          showBorder: showBorder,
          borderWidth: borderWidth,
          borderColor: borderColor,
          borderRadius: borderRadius,
          hingeWidth: hingeWidth,
          hingeLength: hingeLength,
          hingeColor: hingeColor,
        ),
      ],
    );
  }
}