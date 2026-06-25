import 'package:flutter/material.dart';
import 'package:web_clock_clone/widgets/flipclock/half_card.dart';

class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.digit,
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

  final String digit;
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

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Stage 1 (0.0 → 0.5): old TOP flap rotates from 0 → -90° (folds down into hinge)
  late Animation<double> _topFlapFold;

  // Stage 2 (0.5 → 1.0): new BOTTOM flap rotates from +90° → 0 (unfolds downward)
  late Animation<double> _botFlapUnfold;

  String _prevDigit = '';
  String _currentDigit = '';

  @override
  void initState() {
    super.initState();
    _prevDigit = widget.digit;
    _currentDigit = widget.digit;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _setupAnimations();
  }

  void _setupAnimations() {

    // Stage 1: old top flap folds from face-up (0) to edge-on (-π/2)
    _topFlapFold = Tween<double>(
      begin: 0,
      end: -3.14159265 / 2,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Stage 2: new bottom flap unfolds from edge-on (π/2) to face-down (0)
    _botFlapUnfold = Tween<double>(
      begin: 3.14159265 / 2,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.digit != old.digit) {
      _prevDigit = old.digit;
      _currentDigit = widget.digit;
      _ctrl.forward(from: 0);
    }
    if (widget.flipCurve != old.flipCurve) {
      _setupAnimations();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final isFirstHalf = _ctrl.value < 0.5;

          return Stack(
            children: [
              // ── Layer 1 (back): static NEW top half ──────────────────────────
              // Always visible behind the top flap; revealed as flap folds away.
              Positioned(
                top: 0,
                child: HalfCard(
                  width: widget.width,
                  height: widget.height,
                  digit: _currentDigit,
                  isTop: true,
                  fontSize: widget.digitSize,
                  digitColor: widget.digitColor,
                  backgroundColor: widget.backgroundColor,
                  showBorder: widget.showBorder,
                  borderWidth: widget.borderWidth,
                  borderColor: widget.borderColor,
                  borderRadius: widget.borderRadius,
                ),
              ),

              // ── Layer 2 (back): static OLD bottom half ────────────────────────
              // Always visible behind the bottom flap; hidden until flap unfolds.
              Positioned(
                top: widget.height / 2,
                child: HalfCard(
                  width: widget.width,
                  height: widget.height,
                  digit: _prevDigit,
                  isTop: false,
                  fontSize: widget.digitSize,
                  digitColor: widget.digitColor,
                  backgroundColor: widget.backgroundColor,
                  showBorder: widget.showBorder,
                  borderWidth: widget.borderWidth,
                  borderColor: widget.borderColor,
                  borderRadius: widget.borderRadius,
                ),
              ),

              // ── Layer 3 (front): new BOTTOM flap (stage 2) ───────────────────
              // Starts edge-on at the hinge, unfolds downward to reveal new bottom.
              // Only shown during second half of animation (and stays at rest = 0).
              if (!isFirstHalf || _ctrl.value == 0)
                Positioned(
                  top: widget.height / 2,
                  child: Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(_ctrl.value == 0 ? 0 : _botFlapUnfold.value),
                    child: HalfCard(
                      width: widget.width,
                      height: widget.height,
                      digit: _currentDigit,
                      isTop: false,
                      fontSize: widget.digitSize,
                      digitColor: widget.digitColor,
                      backgroundColor: widget.backgroundColor,
                      showBorder: widget.showBorder,
                      borderWidth: widget.borderWidth,
                      borderColor: widget.borderColor,
                      borderRadius: widget.borderRadius,
                      shadow: !isFirstHalf,
                      hingeWidth: widget.hingeWidth,
                      hingeLength: widget.hingeLength,
                      hingeColor: widget.hingeColor,
                    ),
                  ),
                ),

              // ── Layer 4 (front): old TOP flap (stage 1) ──────────────────────
              // Starts face-up, folds down toward the hinge.
              // Only shown during first half of animation (and at rest = 0).
              if (isFirstHalf)
                Positioned(
                  top: 0,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(_topFlapFold.value),
                    child: HalfCard(
                      width: widget.width,
                      height: widget.height,
                      digit: _prevDigit,
                      isTop: true,
                      fontSize: widget.digitSize,
                      digitColor: widget.digitColor,
                      backgroundColor: widget.backgroundColor,
                      showBorder: widget.showBorder,
                      borderWidth: widget.borderWidth,
                      borderColor: widget.borderColor,
                      borderRadius: widget.borderRadius,
                      shadow: isFirstHalf && _ctrl.value > 0,
                      hingeWidth: widget.hingeWidth,
                      hingeLength: widget.hingeLength,
                      hingeColor: widget.hingeColor,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}