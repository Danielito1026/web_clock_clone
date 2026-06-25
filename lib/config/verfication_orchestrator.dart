import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/config/feature_config.dart';
import 'package:web_clock_clone/enums/verification_step.dart';
import 'package:web_clock_clone/network/cancel_token_manager.dart';
import 'package:web_clock_clone/permissions/camera_permission_status.dart';

enum PipelineState {
  idle, // before buildPipeline() is called
  ready, // steps built, permission granted
  permissionDenied, // camera soft-denied, retryable
  permissionPermanentlyDenied, // must open device settings
  configError, // caught from validateConfig()
}

class VerificationOrchestrator extends Notifier<PipelineState> {
  List<VerificationStep> _activeSteps = [];
  int _currentStepIndex = 0;

  // Owned here so AppLifecycleObserver and step notifiers can reach it
  // through the orchestrator rather than as a separate provider.
  final cancelTokenManager = CancelTokenManager();

  @override
  PipelineState build() => PipelineState.idle;

  // ---------------------------------------------------------------------------
  // Read by go_router redirect — never throws.
  // Returns null when the pipeline has not started or is already complete.
  // ---------------------------------------------------------------------------

  VerificationStep? get currentStep {
    if (_activeSteps.isEmpty) return null;
    if (_currentStepIndex >= _activeSteps.length) return null;
    return _activeSteps[_currentStepIndex];
  }

  bool get isComplete =>
      _activeSteps.isNotEmpty && _currentStepIndex >= _activeSteps.length;

  // ---------------------------------------------------------------------------
  // buildPipeline — called once when featureConfigProvider resolves.
  // Also re-called from PermissionErrorScreen "Try Again" tap.
  // ---------------------------------------------------------------------------

  Future<void> buildPipeline(FeatureConfig config) async {
    _activeSteps = [];
    _currentStepIndex = 0;

    // Build step list in fixed order: login → qr → face
    if (config.loginEnabled) _activeSteps.add(VerificationStep.login);
    if (config.qrEnabled) _activeSteps.add(VerificationStep.qr);
    if (config.faceEnabled) _activeSteps.add(VerificationStep.face);

    if (config.needsCamera) {
      final permStatus = await PermissionHelper.checkCamera();
      switch (permStatus) {
        case CameraPermissionStatus.granted:
          state = PipelineState.ready;
        case CameraPermissionStatus.denied:
          state = PipelineState.permissionDenied;
          return;
        case CameraPermissionStatus.permanentlyDenied:
          state = PipelineState.permissionPermanentlyDenied;
          return;
      }
    } else {
      state = PipelineState.ready;
    }
  }

  // ---------------------------------------------------------------------------
  // advanceStep — called by step notifiers on success.
  // Never navigates directly; go_router redirect fires from state notification.
  // ---------------------------------------------------------------------------

  void advanceStep() {
    _currentStepIndex++;
    // Re-assign state to the same value so Riverpod notifies listeners and
    // go_router's redirect callback re-evaluates currentStep / isComplete.
    // ignore: invalid_use_of_protected_member
    ref.notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // resetToFirstStep — background reset.
  // Clears step state only. Does NOT rebuild the pipeline (v1.0 bug).
  // go_router redirect re-evaluates automatically once the app resumes.
  // ---------------------------------------------------------------------------

  void resetToFirstStep() {
    _currentStepIndex = 0;
    cancelTokenManager.cancelAll();
    // Step notifiers watch PipelineState; emitting ready again signals them
    // to clear their own state without the orchestrator knowing their details.
    state = PipelineState.ready;
  }

  // ---------------------------------------------------------------------------
  // resetToHome — max retries hit on any step.
  // Full flush: clears steps so isComplete returns false and go_router
  // redirects to home. Step notifiers flush credentials + UUIDs on idle.
  // ---------------------------------------------------------------------------

  void resetToHome() {
    _currentStepIndex = 0;
    _activeSteps = [];
    cancelTokenManager.cancelAll();
    state = PipelineState.idle;
  }
}