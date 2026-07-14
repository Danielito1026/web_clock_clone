import 'package:web_clock_clone/config/face_liveness_config.dart';
import 'package:web_clock_clone/enums/liveness_challenge.dart';

class FeatureConfig {
  final bool loginEnabled;
  final bool qrEnabled;
  final bool faceEnabled;

  /// Only present when faceEnabled is true.
  /// validateConfig() enforces this invariant.
  final FaceLivenessConfig? faceLivenessConfig;

  const FeatureConfig({
    required this.loginEnabled,
    required this.qrEnabled,
    required this.faceEnabled,
    this.faceLivenessConfig,
  });

  /// Whether camera permission is needed for this config.
  /// Used by VerificationOrchestrator to decide whether to
  /// call PermissionHelper.checkCamera() during buildPipeline().
  bool get needsCamera => qrEnabled || faceEnabled;

  /// Hardcoded local config — replace this with a backend fetch later.
  /// Swap the body of featureConfigProvider to call an API instead.
  factory FeatureConfig.hardcoded() {
    return FeatureConfig(
      loginEnabled: true,
      qrEnabled: true,
      faceEnabled: true,
      faceLivenessConfig: FaceLivenessConfig(
        isRandom: false,
        challengeSequence: [
          LivenessChallenge.blink,
          LivenessChallenge.smile,
          LivenessChallenge.turnLeft,
        ],
      ),
    );
  }

  factory FeatureConfig.fromJson(Map<String, dynamic> json) {
    return FeatureConfig(
      loginEnabled: json['loginEnabled'] as bool? ?? false,
      qrEnabled: json['qrEnabled'] as bool? ?? false,
      faceEnabled: json['faceEnabled'] as bool? ?? false,
      faceLivenessConfig: json['faceLivenessConfig'] != null
          ? FaceLivenessConfig.fromJson(
              json['faceLivenessConfig'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'loginEnabled': loginEnabled,
    'qrEnabled': qrEnabled,
    'faceEnabled': faceEnabled,
    'faceLivenessConfig': faceLivenessConfig?.toJson(),
  };
}
