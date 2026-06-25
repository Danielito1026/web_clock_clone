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

import 'package:web_clock_clone/config/config_exception.dart';
import 'package:web_clock_clone/config/feature_config.dart';

class FeatureConfigRepository {
  const FeatureConfigRepository();

  Future<FeatureConfig> fetchConfig() async {
    // ── Hardcoded (swap this block for a Dio call later) ──────────────────
    final config = FeatureConfig.hardcoded();
    // ──────────────────────────────────────────────────────────────────────

    // Always validate before returning — throws ConfigException on invalid
    validateConfig(config);

    return config;
  }
}