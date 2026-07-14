import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/enums/event_type.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';

class HomeState {
  final EventType selectedEventType;
  final String companyCode;

  const HomeState({
    this.selectedEventType = EventType.timeIn,
    this.companyCode = '',
  });

  HomeState copyWith({EventType? selectedEventType, String? companyCode}) {
    return HomeState(
      selectedEventType: selectedEventType ?? this.selectedEventType,
      companyCode: companyCode ?? this.companyCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          runtimeType == other.runtimeType &&
          selectedEventType == other.selectedEventType &&
          companyCode == other.companyCode;

  @override
  int get hashCode => Object.hash(selectedEventType, companyCode);
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    // Seed from the persisted cache so returning employees don't have to
    // re-type their company code every launch.
    final cached = ref.watch(cachedCompanyConfigProvider).value;
    return HomeState(
      selectedEventType: EventType.timeIn,
      companyCode: cached?.companyCode ?? '',
    );
  }

  /// Updates the selected event type (Time In / Time Out).
  /// Preserved across background resets — only cleared by [reset()].
  void selectEventType(EventType type) {
    state = HomeState(selectedEventType: type);
  }

  /// Called as the employee types / on Start tap. NOT touched by reset() —
  /// company code survives max retries, app kill, and successful
  /// submission alike. It only changes via explicit user edit.
  void setCompanyCode(String code) {
    state = state.copyWith(companyCode: code);
  }

  /// Partial reset — returns to default [EventType.timeIn].
  /// Called when the orchestrator calls [resetToHome()] (max retries or
  /// successful submission). NOT called on background reset.
  void reset() {
    state = state.copyWith(selectedEventType: EventType.timeIn);
  }
}

final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
