import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_clock_clone/config/verfication_orchestrator.dart';
import 'package:web_clock_clone/enums/verification_step.dart';
import 'package:web_clock_clone/pages/config_error_screen.dart';
import 'package:web_clock_clone/pages/face_liveness_screen.dart';
import 'package:web_clock_clone/pages/face_ready_screen.dart';
import 'package:web_clock_clone/pages/home_screen.dart';
import 'package:web_clock_clone/pages/login_screen.dart';
import 'package:web_clock_clone/pages/permission_error_screen.dart';
import 'package:web_clock_clone/pages/qr_scanner_screen.dart';
import 'package:web_clock_clone/pages/result_screen.dart';
import 'package:web_clock_clone/pages/splash_screen.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';

// ---------------------------------------------------------------------------
// RouterNotifier — bridges Riverpod → GoRouter reactivity
//
// GoRouter's redirect only re-runs when this notifier calls notifyListeners().
// We watch both featureConfigProvider and verificationOrchestratorProvider
// so any change to either triggers a redirect re-evaluation.
// ---------------------------------------------------------------------------

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Watch featureConfigProvider — re-evaluate redirect on load/error
    _ref.listen(featureConfigProvider, (_, _) => notifyListeners());

    // Watch orchestrator state — re-evaluate redirect on every pipeline change
    _ref.listen(verificationOrchestratorProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState routerState) {
    final currentPath = routerState.matchedLocation;
    final configAsync = _ref.read(featureConfigProvider);

    // 1. Config still loading — keep user on splash, redirect there if somehow
    //    they landed elsewhere (e.g. deep link on cold start).
    if (configAsync is AsyncLoading) {
      return currentPath == '/splash' ? null : '/splash';
    }

    // 2. Config loaded or errored — splash is no longer a valid destination.
    //    Redirect away immediately so the user never gets stuck on it.
    if (currentPath == '/splash') {
      Future.delayed(const Duration(seconds: 1));
      if (configAsync is AsyncError) return '/error/config';
      return '/'; // config loaded successfully → go to home
    }

    // 3. Config failed — hard block
    if (configAsync is AsyncError) return '/error/config';

    // 4. Read pipeline state
    final pipelineState = _ref.read(verificationOrchestratorProvider);
    final orchestrator = _ref.read(verificationOrchestratorProvider.notifier);

    // 5. Permission errors
    if (pipelineState == PipelineState.permissionDenied) {
      return '/error/permission?type=denied';
    }
    if (pipelineState == PipelineState.permissionPermanentlyDenied) {
      return '/error/permission?type=permanent';
    }

    // 6. Pipeline idle — stay on home
    if (pipelineState == PipelineState.idle) return null;

    // 7. Pipeline complete — go to result
    if (orchestrator.isComplete) return '/result';

    // 8. Route to current active step
    return switch (orchestrator.currentStep) {
      VerificationStep.login => '/verify/login',
      VerificationStep.qr   => '/verify/qr',
      VerificationStep.face => _faceRedirect(currentPath),
      null                  => null,
    };
  }

  /// For the face step, only redirect to /verify/face-ready if the user
  /// is not already on a face-related route. This prevents the redirect
  /// from kicking the employee back to the ready screen while they are
  /// actively on /verify/face doing liveness challenges.
  String? _faceRedirect(String currentPath) {
    const faceRoutes = {'/verify/face-ready', '/verify/face'};
    if (faceRoutes.contains(currentPath)) {
      return null;
    } // already where we need to be
    return '/verify/face-ready';
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash', // ← start here on cold launch
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/verify/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify/qr',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/verify/face-ready',
        builder: (context, state) => const FaceReadyScreen(),
      ),
      GoRoute(
        path: '/verify/face',
        builder: (context, state) => const FaceLivenessScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: '/error/config',
        builder: (context, state) => const ConfigErrorScreen(),
      ),
      GoRoute(
        path: '/error/permission',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'denied';
          return PermissionErrorScreen(type: type);
        },
      ),
    ],
  );
});
