import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/enums/event_type.dart';
import 'package:web_clock_clone/providers/home_notifier_provider.dart';
import 'package:web_clock_clone/widgets/event_button.dart';

class EventSelector extends ConsumerWidget {
  const EventSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    return Row(
      children: [
        Expanded(
          child: EventButton(
            event: EventType.timeIn,
            selected: homeState.selectedEventType == EventType.timeIn,
            enabled: homeState.selectedEventType == EventType.timeIn,
            onPressed: () {
              ref
                  .read(homeNotifierProvider.notifier)
                  .selectEventType(EventType.timeIn);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: EventButton(
            event: EventType.timeOut,
            selected: homeState.selectedEventType == EventType.timeOut,
            enabled: homeState.selectedEventType == EventType.timeOut,
            onPressed: () {
              ref
                  .read(homeNotifierProvider.notifier)
                  .selectEventType(EventType.timeOut);
            },
          ),
        ),
      ],
    );
  }
}
