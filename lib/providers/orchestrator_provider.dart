import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_clock_clone/config/feature_config.dart';
import 'package:web_clock_clone/config/verfication_orchestrator.dart';
import 'package:web_clock_clone/services/feature_config_service.dart';

final featureConfigRepositoryProvider = Provider<FeatureConfigRepository>(
  (ref) => const FeatureConfigRepository(),
);

final featureConfigProvider = FutureProvider<FeatureConfig>((ref) async {
  final repository = ref.read(featureConfigRepositoryProvider);
  return repository.fetchConfig();
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
