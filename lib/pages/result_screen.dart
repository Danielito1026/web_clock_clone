import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_clock_clone/providers/attendance_submission_notifier.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';


class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionAsync = ref.watch(attendanceSubmissionProvider);
    final record = submissionAsync.value;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Success icon ───────────────────────────────────────────────
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),

              // ── Success heading ────────────────────────────────────────────
              const Text(
                'Attendance Recorded',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (record?.message != null) ...[
                Text(
                  record!.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 24),

              // ── Entry details ──────────────────────────────────────────────
              if (record != null) ...[
                _DetailRow(
                  label: 'Event',
                  value: record.eventType == 'time_in' ? 'Time In' : 'Time Out',
                ),
                _DetailRow(label: 'Employee', value: record.username),
                _DetailRow(label: 'Company', value: record.companyCode),
                _DetailRow(label: 'Timestamp', value: record.timestamp),
              ],

              const SizedBox(height: 48),

              // ── Back to home button ────────────────────────────────────────
              // Uses context.go('/') — not Navigator.pop() — to ensure the
              // full route stack is replaced, not just popped.
              ElevatedButton(
                onPressed: () {
                  ref.read(attendanceSubmissionProvider.notifier).reset();
                  ref.read(verificationOrchestratorProvider.notifier).resetToHome();
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}