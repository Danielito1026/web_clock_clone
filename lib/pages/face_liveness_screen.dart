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
    final configAsync = ref.watch(featureConfigProvider);
    final notifier = ref.read(faceNotifierProvider.notifier);
    final faceAsync = ref.watch(faceNotifierProvider);

    return Scaffold(
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Could not load face liveness configuration.\n\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (config) {
          // Hard block if face liveness config is missing from server response.
          if (config.faceLivenessConfig == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Face liveness is not configured. '
                  'Please contact your administrator.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final faceState = faceAsync.value;
          final isTimeout = faceState?.status == FaceStatus.timeout;
          final attemptsRemaining = notifier.attemptsRemaining;

          return Stack(
            children: [
              // ── FaceLivenessWidget ───────────────────────────────────────
              // The widget is fully self-contained:
              //   - Creates and starts its own ChallengeDirector with config
              //   - Owns camera init/dispose and ML Kit validator
              //   - Registers its own WidgetsBindingObserver for camera cleanup
              //
              // On timeout, the widget fires onTimeout. FaceNotifier decides
              // whether to retry or reset to home. If retrying, the screen
              // stays mounted and we use a ValueKey on the widget to force
              // Flutter to remount it fresh — giving it a new director/session.
              FaceLivenessWidget(
                // Key changes on each retry → forces widget remount → fresh
                // ChallengeDirector and session timer, same config.
                key: ValueKey('face_session_$attemptsRemaining'),
                config: config.faceLivenessConfig!,
                onPass: () => notifier.onPass(),
                onTimeout: () => notifier.onTimeout(),
                onUnsupportedDevice: () => context.go('/')
              ),

              // ── Timeout banner (brief feedback before widget remounts) ────
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
          );
        },
      ),
    );
  }
}
