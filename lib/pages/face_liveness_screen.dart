import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_clock_clone/providers/face_notifier.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';
import 'package:web_clock_clone/widgets/face_liveness/face_liveness_widget.dart';

/// Screen wrapper for FaceLivenessWidget.
///
/// Responsibilities:
///   - Read FaceLivenessConfig from featureConfigProvider
///   - Wire FaceLivenessWidget callbacks to FaceNotifier
///   - Show loading/error state while config resolves
///   - Handle unsupported device (hard block)
///
/// Does NOT register its own WidgetsBindingObserver.
/// FaceLivenessWidget already registers one internally (per its own doc) for
/// camera disposal on pause. The root AppLifecycleObserver handles the
/// pipeline-level reset. A third observer here would be redundant.
class FaceLivenessScreen extends ConsumerWidget {
  const FaceLivenessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orchestrator = ref.read(verificationOrchestratorProvider.notifier);
    final config = orchestrator.lastConfig;
    final notifier = ref.read(faceNotifierProvider.notifier);
    final faceAsync = ref.watch(faceNotifierProvider);

    // Hard block if, for any reason, we reached this screen without a
    // valid face config — shouldn't happen (validateConfig() guarantees
    // faceEnabled implies faceLivenessConfig is present), but fail safe
    // rather than null-check-crash.
    if (config?.faceLivenessConfig == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Face Verification')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Face liveness is not configured. '
              'Please contact your administrator.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final faceState = faceAsync.value;
    final isTimeout = faceState?.status == FaceStatus.timeout;
    final attemptsRemaining = notifier.attemptsRemaining;

    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.face, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Face Liveness Verification',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            FaceLivenessWidget(
              key: ValueKey('face_session_$attemptsRemaining'),
              config: config!.faceLivenessConfig!,
              onPass: (file) => notifier.onPass(file),
              onTimeout: () => notifier.onTimeout(),
              onUnsupportedDevice: () => context.go('/'),
            ),
            if (isTimeout)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    color: Colors.orange.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      'Time\'s up. $attemptsRemaining attempt(s) remaining.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
