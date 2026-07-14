import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Shown at `/error/permission?type=denied` or `?type=permanent`.
///
/// - `denied`    → soft denial; "Try Again" re-calls [buildPipeline()].
/// - `permanent` → user must open device settings; "Open Settings" is shown.
///
/// There is no back navigation — the employee cannot bypass the permission
/// check by pressing back.
class PermissionErrorScreen extends ConsumerWidget {
  final String type; // 'denied' | 'permanent'

  const PermissionErrorScreen({super.key, required this.type});

  bool get _isPermanent => type == 'permanent';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      // Prevent hardware back button from bypassing the permission gate.
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.no_photography_outlined,
                  size: 72,
                  color: Colors.orange.shade400,
                ),
                const SizedBox(height: 24),

                // ── Heading ──────────────────────────────────────────────────
                const Text(
                  'Camera Permission Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ── Body copy — differs by denial type ───────────────────────
                Text(
                  _isPermanent
                      ? 'Camera access has been permanently denied. '
                            'Please open your device Settings and enable the '
                            'camera permission for this app, then return here.'
                      : 'This app needs camera access to scan QR codes '
                            'and verify your identity. '
                            'Please grant the permission when prompted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Action button ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPermanent
                        ? () => openAppSettings()
                        : () => ref
                              .read(verificationOrchestratorProvider.notifier)
                              .retryPermissionCheck(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isPermanent ? 'Open Settings' : 'Try Again',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
