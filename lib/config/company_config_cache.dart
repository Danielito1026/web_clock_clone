import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_clock_clone/config/feature_config.dart';

class CachedCompanyConfig {
  final String companyCode;
  final FeatureConfig config;

  const CachedCompanyConfig({required this.companyCode, required this.config});
}

class CompanyConfigCache {
  static const _companyCodeKey = 'cached_company_code';
  static const _featureConfigKey = 'cached_feature_config';

  Future<CachedCompanyConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final companyCode = prefs.getString(_companyCodeKey);
    final configJson = prefs.getString(_featureConfigKey);

    if (companyCode == null || companyCode.isEmpty || configJson == null) {
      return null;
    }

    try {
      final config = FeatureConfig.fromJson(
        jsonDecode(configJson) as Map<String, dynamic>,
      );
      return CachedCompanyConfig(companyCode: companyCode, config: config);
    } catch (_) {
      // Corrupt or outdated cache shape (e.g. after a FeatureConfig field
      // change) — treat as no cache rather than crash the home screen.
      return null;
    }
  }

  Future<void> save(String companyCode, FeatureConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyCodeKey, companyCode);
    await prefs.setString(_featureConfigKey, jsonEncode(config.toJson()));
  }
}