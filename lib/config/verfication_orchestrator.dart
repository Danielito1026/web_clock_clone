import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/config/company_code_not_found_exception.dart';
import 'package:web_clock_clone/config/config_exception.dart';
import 'package:web_clock_clone/config/feature_config.dart';
import 'package:web_clock_clone/enums/verification_step.dart';
import 'package:web_clock_clone/network/cancel_token_manager.dart';
import 'package:web_clock_clone/permissions/camera_permission_status.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';

enum PipelineState {
  idle, // before startPipeline() is called
  loadingConfig, // fetching FeatureConfig for a (new) company code
  ready, // steps built, permission granted
  companyCodeInvalid, // backend didn't recognize the company code — inline-fixable
  permissionDenied, // camera soft-denied, retryable
  permissionPermanentlyDenied, // must open device settings
  configError, // company found, but validateConfig() threw — hard block
}

class VerificationOrchestrator extends Notifier<PipelineState> {
  List<VerificationStep> _activeSteps = [];
  int _currentStepIndex = 0;
  FeatureConfig? _lastConfig;
  FeatureConfig? get lastConfig => _lastConfig;

  /// Set when state becomes companyCodeInvalid or configError, so the UI
  /// can render a specific message. Cleared at the top of every
  /// startPipeline() call.
  String? lastError;

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
  // startPipeline — called by HomeScreen's Start button with the entered
  // company code. Checks the cache first; only calls the backend when the
  // company code differs from what's cached.
  // ---------------------------------------------------------------------------

  Future<void> startPipeline(String companyCode) async {
    if (state == PipelineState.loadingConfig) return; // double-tap guard

    lastError = null;

    final cache = ref.read(companyConfigCacheProvider);
    final cached = await cache.load();

    FeatureConfig? config;

    if (cached != null && cached.companyCode == companyCode) {
      try {
        validateConfig(cached.config);
        config = cached.config;
      } on ConfigException {
        // Stale/invalid cached shape — don't hard-block on a local caching
        // problem, fall through to a fresh fetch below.
        config = null;
      }
    }

    if (config == null) {
      state = PipelineState.loadingConfig;

      final repository = ref.read(featureConfigRepositoryProvider);
      try {
        config = await repository.fetchConfig(companyCode);
      } on CompanyCodeNotFoundException catch (e) {
        lastError = e.message;
        state = PipelineState.companyCodeInvalid;
        return;
      } on ConfigException catch (e) {
        lastError = e.toString();
        state = PipelineState.configError;
        return;
      }
      await cache.save(companyCode, config);
    }

    await buildPipeline(config);
  }

  // ---------------------------------------------------------------------------
  // buildPipeline — builds the active step list + checks camera permission.
  // Called by startPipeline(), and again by retryPermissionCheck() below
  // (no new fetch needed — same config, permission may have changed).
  // ---------------------------------------------------------------------------

  Future<void> buildPipeline(FeatureConfig config) async {
    _lastConfig = config;
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

  /// Called from PermissionErrorScreen's "Try Again" — re-checks permission
  /// against the last fetched config without hitting the network again.
  Future<void> retryPermissionCheck() async {
    if (_lastConfig != null) {
      await buildPipeline(_lastConfig!);
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
