import 'package:flutter/material.dart';

class AmPmBadge extends StatelessWidget {
  const AmPmBadge({
    super.key,
    required this.label,
    this.digitColor,
    this.backgroundColor,
  });

  final String label;
  final Color? digitColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: ['AM', 'PM'].map((p) {
        final active = p == label;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36,
          height: 28,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: active
                ? (backgroundColor ?? const Color(0xFFB71C1C))
                : const Color(0xFF1E1E26),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active
                  ? (backgroundColor ?? const Color(0xFFB71C1C))
                  : const Color(0xFF2A2A35),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            p,
            style: TextStyle(
              color: active
                  ? (digitColor ?? Colors.white)
                  : const Color(0xFF4A4A60),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        );
      }).toList(),
    );
  }
}
