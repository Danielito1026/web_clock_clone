import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/config/verfication_orchestrator.dart';
import 'package:web_clock_clone/providers/home_notifier_provider.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';
import 'package:web_clock_clone/widgets/event_selector.dart';
import 'package:web_clock_clone/widgets/flipclock/flip_clock.dart';
import 'package:web_clock_clone/widgets/input_form_field.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _companyCodeController;

  @override
  void initState() {
    super.initState();
    _companyCodeController = TextEditingController(
      text: ref.read(homeNotifierProvider).companyCode,
    );
  }

  @override
  void dispose() {
    _companyCodeController.dispose();
    super.dispose();
  }

  void _onStart() {
    final trimmed = _companyCodeController.text.trim();
    if (trimmed.isEmpty) return;

    ref.read(homeNotifierProvider.notifier).setCompanyCode(trimmed);
    ref.read(verificationOrchestratorProvider.notifier).startPipeline(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    // Keep the field in sync if the cached company code resolves after
    // this screen has already built (cold-start race with the cache read).
    ref.listen(homeNotifierProvider, (previous, next) {
      if (previous?.companyCode != next.companyCode &&
          _companyCodeController.text != next.companyCode) {
        _companyCodeController.text = next.companyCode;
      }
    });

    final pipelineState = ref.watch(verificationOrchestratorProvider);
    final orchestrator = ref.watch(verificationOrchestratorProvider.notifier);

    final isLoadingConfig = pipelineState == PipelineState.loadingConfig;
    final isInvalidCode = pipelineState == PipelineState.companyCodeInvalid;
    final canStart =
        (pipelineState == PipelineState.idle || isInvalidCode) &&
        _companyCodeController.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlipClock(
                hourFormat: FlipClockHourFormat.h12,
                digitSize: 45,
                width: 35,
                height: 56,
              ),

              const SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF191B21),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    InputFormField(
                      labelText: 'Company Code',
                      isRequired: true,
                      prefixIcon: const Icon(Icons.apartment),
                      hint: 'Enter your company code',
                      controller: _companyCodeController,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      onChanged: (_) => setState(() {}), // re-evaluate canStart
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      errorText: isInvalidCode
                          ? (orchestrator.lastError ??
                                'Company code not recognized.')
                          : null,
                    ),

                    const SizedBox(height: 24),

                    const EventSelector(),

                    const SizedBox(height: 40),

                    _StartButton(
                      label: isLoadingConfig ? 'Loading...' : 'Start',
                      enabled: canStart && !isLoadingConfig,
                      onTap: canStart && !isLoadingConfig ? _onStart : null,
                    ),
                  ],
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFFC00000),
          disabledBackgroundColor: const Color(0xFF15171B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.white : Color(0xFF737477),
          ),
        ),
      ),
    );
  }
}
