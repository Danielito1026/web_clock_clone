import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/config/verfication_orchestrator.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';
import 'package:web_clock_clone/widgets/event_selector.dart';
import 'package:web_clock_clone/widgets/flipclock/flip_clock.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(featureConfigProvider);
    final pipelineState = ref.watch(verificationOrchestratorProvider);

    // Start button is active only when config has loaded and pipeline is idle.
    final canStart =
        configAsync is AsyncData && pipelineState == PipelineState.idle;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Flip clock (existing widget — integrate here) ──────────────
              // Replace the placeholder below with your FlipClockWidget once
              // you have it imported. Do not rebuild the clock logic.
              const FlipClock(hourFormat: .h12, digitSize: 45, width: 35, height: 56),

              const SizedBox(height: 48),

              // ── Event type toggle ──────────────────────────────────────────
              const EventSelector(),

              const SizedBox(height: 40),

              // ── Start button ───────────────────────────────────────────────
              configAsync.when(
                loading: () => const _StartButton(
                  label: 'Loading...',
                  enabled: false,
                  onTap: null,
                ),
                error: (_, _) => const _StartButton(
                  label: 'Unavailable',
                  enabled: false,
                  onTap: null,
                ),
                data: (config) => _StartButton(
                  label: 'Start',
                  enabled: canStart,
                  onTap: canStart
                      ? () => ref
                            .read(verificationOrchestratorProvider.notifier)
                            .buildPipeline(config)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _StartButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: theme.colorScheme.primary,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
