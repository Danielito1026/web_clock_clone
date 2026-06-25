import 'package:flutter/material.dart';
import 'dart:async';

class Separator extends StatefulWidget {
  final String char;
  final double? separatorWidth;
  final Color? separatorColor;
  final Color? separatorBackgroundColor;
  final bool separatorAnimate;
  final double digitSize;

  const Separator({
    super.key,
    required this.char,
    this.separatorWidth,
    this.separatorColor,
    this.separatorBackgroundColor,
    this.separatorAnimate = false,
    required this.digitSize,
  });

  @override
  State<Separator> createState() => _SeparatorState();
}

class _SeparatorState extends State<Separator> {
  bool _visible = true;
  Timer? _blink;

  @override
  void initState() {
    super.initState();
    _blink = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted) setState(() => _visible = !_visible);
    });
  }

  @override
  void dispose() {
    _blink?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.separatorWidth ?? 4),
      child: AnimatedOpacity(
        opacity: _visible
            ? 1.0
            : widget.separatorAnimate
            ? 0.15
            : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: widget.separatorBackgroundColor != null
              ? BoxDecoration(
                  color: widget.separatorBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          padding: widget.separatorBackgroundColor != null
              ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
              : EdgeInsets.zero,
          child: Text(
            widget.char,
            style: TextStyle(
              color: widget.separatorColor ?? const Color(0xFFB71C1C),
              fontSize: widget.digitSize * 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
