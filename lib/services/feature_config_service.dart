// ---------------------------------------------------------------------------
// FeatureConfigRepository — single source of truth for FeatureConfig.
//
// Currently returns the hardcoded config.
// To switch to the backend later, replace the body of fetchConfig() with
// a Dio GET to /api/config/features and parse the JSON response.
//
// validateConfig() is always called here regardless of source —
// the orchestrator never receives an invalid config.
// ---------------------------------------------------------------------------

import 'package:web_clock_clone/config/company_code_not_found_exception.dart';
import 'package:web_clock_clone/config/config_exception.dart';
import 'package:web_clock_clone/config/face_liveness_config.dart';
import 'package:web_clock_clone/config/feature_config.dart';
import 'package:web_clock_clone/enums/liveness_challenge.dart';

class FeatureConfigRepository {
  const FeatureConfigRepository();

  Future<FeatureConfig> fetchConfig(String companyCode) async {
    // ── DEMO: Return different configs based on company code ──
    // Use these codes to test different scenarios:
    // - "invalid": Throws ConfigException (invalid config structure)
    // - "notfound": Throws CompanyCodeNotFoundException
    // - "empty": Empty company code (throws CompanyCodeNotFoundException)
    // - "all": All features enabled
    // - "login_only": Only login enabled
    // - "qr_only": Only QR enabled
    // - "face_only": Only face enabled (invalid - throws ConfigException)
    // - "login_face": Login + Face enabled
    // - "qr_face": QR + Face enabled
    // - "login_qr": Login + QR enabled
    // - "login_qr_face": All three enabled
    // - "face_no_challenges": Face enabled but no challenges (invalid)
    // - "face_empty_challenges": Face enabled with empty challenge list (invalid)
    // - "random_challenges": Face with random challenges
    // - "specific_challenges": Face with specific challenge sequence

    final trimmedCode = companyCode.trim();

    // Handle empty company code
    if (trimmedCode.isEmpty) {
      throw CompanyCodeNotFoundException(companyCode);
    }

    // Handle company not found
    if (trimmedCode.toLowerCase() == 'notfound') {
      throw CompanyCodeNotFoundException(
        companyCode,
        message: 'Company code "$companyCode" not recognized.',
      );
    }

    // Handle invalid configs (these will throw ConfigException)
    if (trimmedCode.toLowerCase() == 'face_only') {
      // Invalid: Face as standalone
      final config = FeatureConfig(
        loginEnabled: false,
        qrEnabled: false,
        faceEnabled: true,
        faceLivenessConfig: FaceLivenessConfig(
          isRandom: false,
          challengeSequence: [LivenessChallenge.blink, LivenessChallenge.smile],
        ),
      );
      validateConfig(config); // This will throw ConfigException
      return config;
    }

    if (trimmedCode.toLowerCase() == 'face_no_challenges') {
      // Invalid: Face enabled but no liveness config
      final config = FeatureConfig(
        loginEnabled: true,
        qrEnabled: false,
        faceEnabled: true,
        faceLivenessConfig: null, // Missing config
      );
      validateConfig(config); // This will throw ConfigException
      return config;
    }

    if (trimmedCode.toLowerCase() == 'face_empty_challenges') {
      // Invalid: Face enabled with empty challenge list
      final config = FeatureConfig(
        loginEnabled: true,
        qrEnabled: false,
        faceEnabled: true,
        faceLivenessConfig: FaceLivenessConfig(
          isRandom: false,
          challengeSequence: [], // Empty challenge list
        ),
      );
      validateConfig(config); // This will throw ConfigException
      return config;
    }

    // Valid configurations start here
    switch (trimmedCode.toLowerCase()) {
      case 'all':
      case 'login_qr_face':
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

      case 'login_only':
        return FeatureConfig(
          loginEnabled: true,
          qrEnabled: false,
          faceEnabled: false,
          faceLivenessConfig: null,
        );

      case 'qr_only':
        return FeatureConfig(
          loginEnabled: false,
          qrEnabled: true,
          faceEnabled: false,
          faceLivenessConfig: null,
        );

      case 'login_face':
        return FeatureConfig(
          loginEnabled: true,
          qrEnabled: false,
          faceEnabled: true,
          faceLivenessConfig: FaceLivenessConfig(
            isRandom: false,
            challengeSequence: [
              LivenessChallenge.blink,
              LivenessChallenge.smile,
            ],
          ),
        );

      case 'qr_face':
        return FeatureConfig(
          loginEnabled: false,
          qrEnabled: true,
          faceEnabled: true,
          faceLivenessConfig: FaceLivenessConfig(
            isRandom: false,
            challengeSequence: [
              LivenessChallenge.blink,
              LivenessChallenge.turnLeft,
            ],
          ),
        );

      case 'login_qr':
        return FeatureConfig(
          loginEnabled: true,
          qrEnabled: true,
          faceEnabled: false,
          faceLivenessConfig: null,
        );

      case 'random_challenges':
        return FeatureConfig(
          loginEnabled: true,
          qrEnabled: true,
          faceEnabled: true,
          faceLivenessConfig: FaceLivenessConfig(
            isRandom: true,
            challengeSequence: [
              LivenessChallenge.blink,
              LivenessChallenge.smile,
              LivenessChallenge.turnLeft,
              LivenessChallenge.turnRight,
            ],
          ),
        );

      case 'specific_challenges':
        return FeatureConfig(
          loginEnabled: true,
          qrEnabled: false,
          faceEnabled: true,
          faceLivenessConfig: FaceLivenessConfig(
            isRandom: false,
            challengeSequence: [
              LivenessChallenge.smile,
              LivenessChallenge.turnRight,
            ],
          ),
        );

      case 'invalid': // This will throw ConfigException due to no enabled features
        final config = FeatureConfig(
          loginEnabled: false,
          qrEnabled: false,
          faceEnabled: false,
          faceLivenessConfig: null,
        );
        validateConfig(config); // This will throw ConfigException
        return config;

      // Default: Return the standard hardcoded config
      default:
        throw CompanyCodeNotFoundException(
          companyCode,
          message: 'Company code "$companyCode" not recognized.',
        );
    }
  }
}
