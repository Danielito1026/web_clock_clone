import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/providers/qr_notifier.dart';
import 'package:web_clock_clone/widgets/qr_scanner/qr_scanner_widget.dart';

class QrScannerScreen extends ConsumerWidget {
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrAsync = ref.watch(qrNotifierProvider);
    final notifier = ref.read(qrNotifierProvider.notifier);

    final isValidating = qrAsync is AsyncLoading;
    final qrState = qrAsync.value;
    final isFailure = qrState?.status == QRStatus.failure;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          QrScannerWidget(
            onBarcodeDetected: (raw) => notifier.onBarcodeScanned(raw),
          ),

          // ── Loading overlay (validating with backend) ─────────────────────
          if (isValidating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Validating...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // ── Error banner (failure — scanner re-enabled automatically) ─────
          if (isFailure)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      qrState?.errorMessage ?? 'QR code not recognised.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${notifier.attemptsRemaining} attempt(s) remaining. Scan again.',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
