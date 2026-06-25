import 'package:flutter/material.dart';

class DateDisplay extends StatelessWidget {
  const DateDisplay({
    super.key,
    required this.now,
    this.digitColor,
    this.backgroundColor,
  });

  final DateTime now;
  final Color? digitColor;
  final Color? backgroundColor;

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final day = _weekdays[now.weekday - 1];
    final month = _months[now.month - 1];
    final date = '${now.day.toString().padLeft(2, '0')} $month ${now.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFB71C1C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            day,
            style: TextStyle(
              color: digitColor ?? Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          date,
          style: TextStyle(
            color:
                digitColor?.withValues(alpha: 0.6) ?? const Color(0xFF6B6B80),
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
