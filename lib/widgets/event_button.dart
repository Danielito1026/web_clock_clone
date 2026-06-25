import 'package:flutter/material.dart';
import 'package:web_clock_clone/enums/event_type.dart';

class EventButton extends StatelessWidget {
  const EventButton({
    super.key,
    required this.event,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final EventType event;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(
        event == EventType.timeIn ? Icons.login_rounded : Icons.logout_rounded,
      ),
      label: Text(
        event == EventType.timeIn ? "TIME IN" : "TIME OUT",
        style: TextStyle(color: selected? Colors.white: Color(0xFF737477),fontWeight: FontWeight.w900),
      ),
      style: FilledButton.styleFrom(
        iconColor: selected? Colors.white: Color(0xFF737477),
        backgroundColor: selected
            ? const Color(0xFFC00000)
            : const Color(0xFF15171B),
        disabledBackgroundColor: const Color(0xFF2A2D34),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
