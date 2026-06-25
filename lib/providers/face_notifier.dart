import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/config/verfication_orchestrator.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';
import 'package:web_clock_clone/services/face_service.dart';
import 'package:web_clock_clone/utils/retry_counter.dart';

enum FaceStatus { idle, active, success, timeout, failure }

class FaceState {
  final String? faceUuid;
  final FaceStatus status;
  final String? errorMessage;

  const FaceState({
    this.faceUuid,
    this.status = FaceStatus.idle,
    this.errorMessage,
  });

  FaceState copyWith({
    String? faceUuid,
    FaceStatus? status,
    String? errorMessage,
  }) {
    return FaceState(
      faceUuid: faceUuid ?? this.faceUuid,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Manages the face liveness step at the pipeline level.
///
/// This notifier does NOT own or touch ChallengeDirector or ChallengeValidator.
/// Those are fully internal to FaceLivenessWidget — the widget constructs,
/// starts, and disposes them on its own lifecycle.
///
/// FaceNotifier's only jobs:
///   1. Track retry attempts across session timeouts
///   2. Call the backend to register the session when the widget reports a pass
///   3. Advance or reset the pipeline based on the outcome
///
/// FaceLivenessScreen wires the widget's onPass/onTimeout callbacks to this
/// notifier's onPass()/onTimeout() methods.
class FaceNotifier extends AsyncNotifier<FaceState> {
  final _retryCounter = RetryCounter();

  VerificationOrchestrator get _orchestrator =>
      ref.read(verificationOrchestratorProvider.notifier);
  FaceService get _repository => ref.read(faceServiceProvider);

  @override
  Future<FaceState> build() async => const FaceState(status: FaceStatus.idle);

  // ---------------------------------------------------------------------------
  // Exposed for the face screen — "X attempts remaining"
  // ---------------------------------------------------------------------------

  int get attemptsRemaining => RetryCounter.maxAttempts - _retryCounter.count;

  // ---------------------------------------------------------------------------
  // onPass — wired to FaceLivenessWidget.onPass
  //
  // All challenges completed within the session timer.
  // Call the backend to register the session and receive face_uuid.
  // ---------------------------------------------------------------------------

  Future<void> onPass() async {
    state = const AsyncLoading();

    final authToken =
        await ref.read(secureStorageProvider).read(key: 'auth_token');

    final cancelToken = _orchestrator.cancelTokenManager.generate();

    final result = await _repository.registerSession(
      authToken: authToken,
      cancelToken: cancelToken,
    );

    if (result.isSuccess) {
      // face_uuid held in state only — never written to disk.
      state = AsyncData(FaceState(
        faceUuid: result.faceUuid,
        status: FaceStatus.success,
      ));
      _orchestrator.advanceStep();
    } else {
      // Backend registration failed — treat as a timeout so the retry
      // counter is shared across both failure modes.
      onTimeout();
    }
  }

  // ---------------------------------------------------------------------------
  // onTimeout — wired to FaceLivenessWidget.onTimeout
  //
  // Session timer expired before all challenges were completed.
  // The widget has already reset its own internal director/timer.
  // FaceNotifier just handles the pipeline-level retry logic.
  // ---------------------------------------------------------------------------

  void onTimeout() {
    _retryCounter.increment();

    if (_retryCounter.hasExceededMax) {
      reset();
      _orchestrator.resetToHome();
    } else {
      state = const AsyncData(FaceState(status: FaceStatus.timeout));
      // FaceLivenessScreen re-mounts FaceLivenessWidget on timeout by
      // watching this status — the widget restarts its own session on mount.
    }
  }

  // ---------------------------------------------------------------------------
  // reset — called on background reset, max retries, or successful submission
  // ---------------------------------------------------------------------------

  void reset() {
    state = const AsyncData(FaceState(status: FaceStatus.idle));
    _retryCounter.reset();
  }
}
final faceServiceProvider = Provider<FaceService>((_) => FaceService());

final faceNotifierProvider = AsyncNotifierProvider<FaceNotifier, FaceState>(
  FaceNotifier.new,
);
