import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';


/// Single [WidgetsBindingObserver] registered at the app root in [main.dart].
///
/// Responsibilities:
/// - [AppLifecycleState.paused]   → background reset (first active step, event type preserved)
/// - [AppLifecycleState.detached] → full reset (equivalent to app kill)
/// - [AppLifecycleState.resumed]  → no-op (go_router redirect re-evaluates automatically)
///
/// Registration and removal are both done in [main.dart] — this class never
/// calls [WidgetsBinding.instance.addObserver] on itself.
class AppLifecycleObserver with WidgetsBindingObserver {
  final WidgetRef ref;

  AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // Background — reset to first active step; event type is preserved.
        ref
            .read(verificationOrchestratorProvider.notifier)
            .resetToFirstStep();

      case AppLifecycleState.detached:
        // App killed — full state flush including credentials.
        ref
            .read(verificationOrchestratorProvider.notifier)
            .resetToHome();

      case AppLifecycleState.resumed:
        // Intentional no-op.
        // go_router's redirect callback re-evaluates currentStep automatically
        // when the orchestrator state was updated during pause/detach.
        break;

      default:
        // hidden, inactive — no action needed.
        break;
    }
  }
}