import 'package:flutter/material.dart';
import 'package:web_clock_clone/widgets/flipclock/am_pm_badge.dart';
import 'dart:async';

import 'package:web_clock_clone/widgets/flipclock/date_display.dart';
import 'package:web_clock_clone/widgets/flipclock/flip_group.dart';
import 'package:web_clock_clone/widgets/flipclock/separator.dart';

enum FlipClockHourFormat { h12, h24 }

enum SeparatorStyle { colon, dot, slash, none }

/// A customizable flip-style clock widget that displays the current time with
/// optional date, seconds, and AM/PM indicators.
///
/// Responsibilities:
///   - Keep the displayed time synchronized with the system clock.
///   - Render animated flip groups for hours, minutes, and optional seconds.
///   - Provide hooks for styling, layout, and separator behavior.
///
/// This widget is not for:
///   - Handling authentication or form input logic.
///   - Replacing a full-featured clock package with advanced timezone support.
///   - Displaying static images or non-time-based content.
///
/// Sample usage:
/// ```dart
/// FlipClock(
///   hourFormat: FlipClockHourFormat.h12,
///   showSeconds: true,
///   showDate: false,
///   digitSize: 45,
///   width: 35,
///   height: 56,
/// )
/// ```
class FlipClock extends StatefulWidget {
  final FlipClockHourFormat hourFormat;
  final bool showAmPm;
  final bool showSeconds;
  final bool showDate;
  final SeparatorStyle separatorStyle;

  // New responsive and customization options
  final double digitSize;
  final double width;
  final double height;
  final AxisDirection flipDirection;
  final Curve? flipCurve;
  final Color? digitColor;
  final Color? backgroundColor;
  final double? separatorWidth;
  final Color? separatorColor;
  final Color? separatorBackgroundColor;
  final bool separatorAnimate;
  final bool? showBorder;
  final double? borderWidth;
  final Color? borderColor;
  final BorderRadius borderRadius;
  final double hingeWidth;
  final double? hingeLength;
  final Color? hingeColor;

  const FlipClock({
    super.key,
    this.hourFormat = FlipClockHourFormat.h24,
    this.showAmPm = true,
    this.showSeconds = true,
    this.showDate = true,
    this.separatorStyle = SeparatorStyle.colon,
    required this.digitSize,
    required this.width,
    required this.height,
    this.flipDirection = AxisDirection.down,
    this.flipCurve,
    this.digitColor,
    this.backgroundColor,
    this.separatorWidth,
    this.separatorColor,
    this.separatorBackgroundColor,
    this.separatorAnimate = false,
    this.showBorder,
    this.borderWidth,
    this.borderColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.hingeWidth = 0.8,
    this.hingeLength,
    this.hingeColor,
  });

  @override
  State<FlipClock> createState() => _FlipClockState();
}

class _FlipClockState extends State<FlipClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _separatorChar {
    switch (widget.separatorStyle) {
      case SeparatorStyle.colon:
        return ':';
      case SeparatorStyle.dot:
        return '·';
      case SeparatorStyle.slash:
        return '/';
      case SeparatorStyle.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final is12h = widget.hourFormat == FlipClockHourFormat.h12;
    final hour = is12h
        ? (_now.hour % 12 == 0 ? 12 : _now.hour % 12)
        : _now.hour;
    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = _now.minute.toString().padLeft(2, '0');
    final secStr = _now.second.toString().padLeft(2, '0');
    final amPm = _now.hour < 12 ? 'AM' : 'PM';

    final sep = _separatorChar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Date row
        if (widget.showDate) ...[
          DateDisplay(
            now: _now,
            digitColor: widget.digitColor,
            backgroundColor: widget.backgroundColor,
          ),
          const SizedBox(height: 12),
        ],

        // Clock digits row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hours
            FlipGroup(
              value: hourStr,
              digitSize: widget.digitSize,
              width: widget.width,
              height: widget.height,
              flipDirection: widget.flipDirection,
              flipCurve: widget.flipCurve,
              digitColor: widget.digitColor,
              backgroundColor: widget.backgroundColor,
              showBorder: widget.showBorder,
              borderWidth: widget.borderWidth,
              borderColor: widget.borderColor,
              borderRadius: widget.borderRadius,
              hingeWidth: widget.hingeWidth,
              hingeLength: widget.hingeLength,
              hingeColor: widget.hingeColor,
            ),

            if (sep.isNotEmpty)
              Separator(
                char: sep,
                separatorWidth: widget.separatorWidth,
                separatorColor: widget.separatorColor,
                separatorBackgroundColor: widget.separatorBackgroundColor,
                digitSize: widget.digitSize,
                separatorAnimate: widget.separatorAnimate,
              ),

            // Minutes
            FlipGroup(
              value: minStr,
              digitSize: widget.digitSize,
              width: widget.width,
              height: widget.height,
              flipDirection: widget.flipDirection,
              flipCurve: widget.flipCurve,
              digitColor: widget.digitColor,
              backgroundColor: widget.backgroundColor,
              showBorder: widget.showBorder,
              borderWidth: widget.borderWidth,
              borderColor: widget.borderColor,
              borderRadius: widget.borderRadius,
              hingeWidth: widget.hingeWidth,
              hingeLength: widget.hingeLength,
              hingeColor: widget.hingeColor,
            ),

            // Seconds
            if (widget.showSeconds) ...[
              if (sep.isNotEmpty)
                Separator(
                  char: sep,
                  separatorWidth: widget.separatorWidth,
                  separatorColor: widget.separatorColor,
                  separatorBackgroundColor: widget.separatorBackgroundColor,
                  digitSize: widget.digitSize,
                ),
              FlipGroup(
                value: secStr,
                digitSize: widget.digitSize,
                width: widget.width,
                height: widget.height,
                flipDirection: widget.flipDirection,
                flipCurve: widget.flipCurve,
                digitColor: widget.digitColor,
                backgroundColor: widget.backgroundColor,
                showBorder: widget.showBorder,
                borderWidth: widget.borderWidth,
                borderColor: widget.borderColor,
                borderRadius: widget.borderRadius,
                hingeWidth: widget.hingeWidth,
                hingeLength: widget.hingeLength,
                hingeColor: widget.hingeColor,
              ),
            ],

            // AM/PM badge
            if (is12h && widget.showAmPm) ...[
              const SizedBox(width: 10),
              AmPmBadge(
                label: amPm,
                digitColor: widget.digitColor,
                backgroundColor: widget.backgroundColor,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
