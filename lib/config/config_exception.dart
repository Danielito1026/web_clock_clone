import 'package:web_clock_clone/config/feature_config.dart';

// ---------------------------------------------------------------------------
// ConfigException — thrown by validateConfig() on invalid FeatureConfig.
// Caught as AsyncError by featureConfigProvider → router → /error/config.
// ---------------------------------------------------------------------------

class ConfigException implements Exception {
  final String message;
  const ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}

// ---------------------------------------------------------------------------
// validateConfig — call this immediately after constructing a FeatureConfig,
// before passing it to VerificationOrchestrator.buildPipeline().
//
// Throws ConfigException on any invalid state.
// Returns void on success — caller proceeds normally.
// ---------------------------------------------------------------------------

void validateConfig(FeatureConfig config) {
  // Rule 1: at least one step must be enabled
  if (!config.loginEnabled && !config.qrEnabled && !config.faceEnabled) {
    throw const ConfigException(
      'No verification steps are enabled. '
      'Enable at least one step in the admin site.',
    );
  }

  // Rule 2: face cannot be standalone
  if (config.faceEnabled &&
      !config.loginEnabled &&
      !config.qrEnabled) {
    throw const ConfigException(
      'Face detection cannot run as a standalone step. '
      'Enable Login or QR in the admin site.',
    );
  }

  // Rule 3: face enabled but no liveness config provided
  if (config.faceEnabled && config.faceLivenessConfig == null) {
    throw const ConfigException(
      'Face detection is enabled but no liveness configuration was provided.',
    );
  }

  // Rule 4: face enabled but challenge list is empty
  if (config.faceEnabled &&
      (config.faceLivenessConfig?.challengeSequence.isEmpty ?? false)) {
    throw const ConfigException(
      'Face detection is enabled but the challenge list is empty. '
      'Add at least one challenge in the admin site.',
    );
  }
}