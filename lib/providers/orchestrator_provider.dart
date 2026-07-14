import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_clock_clone/config/company_config_cache.dart';
// import 'package:web_clock_clone/config/feature_config.dart';
import 'package:web_clock_clone/config/verfication_orchestrator.dart';
import 'package:web_clock_clone/services/feature_config_service.dart';

final featureConfigRepositoryProvider = Provider<FeatureConfigRepository>(
  (ref) => const FeatureConfigRepository(),
);

// final featureConfigProvider = FutureProvider<FeatureConfig>((ref) async {
//   final repository = ref.read(featureConfigRepositoryProvider);
//   return repository.fetchConfig();
// });

final companyConfigCacheProvider = Provider<CompanyConfigCache>(
  (_) => CompanyConfigCache(),
);

/// Read once at boot (and by HomeNotifier.build()) to seed the company
/// code field. Not a source of truth after that — startPipeline() re-reads
/// the cache directly via companyConfigCacheProvider.
final cachedCompanyConfigProvider = FutureProvider<CachedCompanyConfig?>((
  ref,
) {
  return ref.read(companyConfigCacheProvider).load();
});

final verificationOrchestratorProvider =
    NotifierProvider<VerificationOrchestrator, PipelineState>(
      VerificationOrchestrator.new,
    );

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});
