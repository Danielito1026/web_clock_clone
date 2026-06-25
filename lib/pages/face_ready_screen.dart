import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Interstitial screen shown between QR scan success and FaceLivenessScreen.
///
/// Purpose:
///   - Gives the back camera (used by QrScannerWidget) time to fully release
///     its platform resource before FaceLivenessWidget claims the front camera.
///   - Sets the employee's expectation for what's about to happen.
///
/// This is NOT an orchestrator step — the orchestrator still sees
/// VerificationStep.face. The router sends the face step here first;
/// tapping "I'm Ready" pushes directly to /verify/face via context.push().
///
/// The 1-second delay on button tap is the actual camera release window.
/// It feels intentional to the user (button feedback) rather than a blank wait.
class FaceReadyScreen extends StatefulWidget {
  const FaceReadyScreen({super.key});

  @override
  State<FaceReadyScreen> createState() => _FaceReadyScreenState();
}

class _FaceReadyScreenState extends State<FaceReadyScreen> {
  bool _isNavigating = false;

  Future<void> _onReady() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    // 1-second delay — gives QrScannerWidget.dispose() → CameraInputStream
    // .dispose() → CameraController.dispose() time to complete on the platform
    // channel before FaceLivenessWidget requests the front camera.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Push (not go) — keeps /verify/face-ready in the stack so the back
    // button works correctly if the employee wants to re-scan the QR code.
    // The orchestrator's background reset will handle stack cleanup if needed.
    context.push('/verify/face');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Verification'),
        automaticallyImplyLeading: false, // no back button — must tap Ready
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ── Icon ──────────────────────────────────────────────────────
              Icon(
                Icons.face_retouching_natural,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // ── Heading ───────────────────────────────────────────────────
              Text(
                'Face Verification',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ── Instructions ──────────────────────────────────────────────
              Text(
                'We\'ll ask you to perform a few simple actions to verify '
                'your identity. Make sure you are in a well-lit area and '
                'your face is clearly visible.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // ── Tips ──────────────────────────────────────────────────────
              _TipRow(
                icon: Icons.wb_sunny_outlined,
                text: 'Find good lighting',
              ),
              const SizedBox(height: 12),
              _TipRow(
                icon: Icons.remove_red_eye_outlined,
                text: 'Remove glasses if possible',
              ),
              const SizedBox(height: 12),
              _TipRow(
                icon: Icons.stay_current_portrait_outlined,
                text: 'Hold your phone at eye level',
              ),

              const Spacer(),

              // ── Ready button ──────────────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isNavigating ? null : _onReady,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isNavigating
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'I\'m Ready',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tip row ──────────────────────────────────────────────────────────────────

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black45),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.black54, fontSize: 14)),
      ],
    );
  }
}
