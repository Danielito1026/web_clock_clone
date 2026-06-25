import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/enums/event_type.dart';

class HomeState {
  final EventType selectedEventType;

  const HomeState({this.selectedEventType = EventType.timeIn});

  HomeState copyWith({EventType? selectedEventType}) {
    return HomeState(
      selectedEventType: selectedEventType ?? this.selectedEventType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          runtimeType == other.runtimeType &&
          selectedEventType == other.selectedEventType;

  @override
  int get hashCode => selectedEventType.hashCode;
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState(selectedEventType: EventType.timeIn);

  /// Updates the selected event type (Time In / Time Out).
  /// Preserved across background resets — only cleared by [reset()].
  void selectEventType(EventType type) {
    state = HomeState(selectedEventType: type);
  }

  /// Full reset — returns to default [EventType.timeIn].
  /// Called when the orchestrator calls [resetToHome()] (max retries or
  /// successful submission). NOT called on background reset.
  void reset() {
    state = const HomeState(selectedEventType: EventType.timeIn);
  }
}

final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
