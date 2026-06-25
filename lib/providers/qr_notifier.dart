import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/config/verfication_orchestrator.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';
import 'package:web_clock_clone/services/qr_service.dart';
import 'package:web_clock_clone/utils/retry_counter.dart';

enum QRStatus { idle, validating, success, failure }

class QRState {
  final String? qrUuid;
  final QRStatus status;
  final String? errorMessage;

  const QRState({this.qrUuid, this.status = QRStatus.idle, this.errorMessage});

  QRState copyWith({String? qrUuid, QRStatus? status, String? errorMessage}) {
    return QRState(
      qrUuid: qrUuid ?? this.qrUuid,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class QRNotifier extends AsyncNotifier<QRState> {
  final _retryCounter = RetryCounter();

  QRService get _repository => ref.read(qrServiceProvider);
  VerificationOrchestrator get _orchestrator =>
      ref.read(verificationOrchestratorProvider.notifier);

  @override
  Future<QRState> build() async => const QRState(status: QRStatus.idle);

  // ---------------------------------------------------------------------------
  // Exposed for the QR screen — "X attempts remaining"
  // ---------------------------------------------------------------------------

  int get attemptsRemaining => RetryCounter.maxAttempts - _retryCounter.count;

  // ---------------------------------------------------------------------------
  // onBarcodeScanned — called by QrScannerWidget.onBarcodeDetected
  //
  // The scanner widget passes the raw string content of the detected barcode.
  // The notifier reads the auth token from secure storage and sends both
  // to the backend for validation.
  // ---------------------------------------------------------------------------

  Future<void> onBarcodeScanned(String rawContent) async {
    state = const AsyncLoading();

    // Auth token was written to secure storage by LoginNotifier on success.
    // If Login step is disabled, token may be null — backend handles that case.
    final authToken = await ref
        .read(secureStorageProvider)
        .read(key: 'auth_token');

    final cancelToken = _orchestrator.cancelTokenManager.generate();

    final result = await _repository.validate(
      qrContent: rawContent,
      authToken: authToken,
      cancelToken: cancelToken,
    );

    if (result.isSuccess) {
      // qr_uuid held in state only — never written to disk.
      state = AsyncData(
        QRState(qrUuid: result.qrUuid, status: QRStatus.success),
      );

      // BG-0001 — Camera resource contention fix (Part 2 of 2).
      //
      // QrScannerWidget uses CameraInputStream (back camera).
      // FaceLivenessWidget uses CameraInputStream (front camera).
      //
      // advanceStep() notifies RouterNotifier immediately, which pushes
      // FaceLivenessScreen before QrScannerWidget.dispose() has released the
      // back camera on the platform channel. The front camera then tries to
      // initialize while the back camera resource is still held, causing
      // CameraInputStream._initCamera() to fail and trigger onInitFailure.
      //
      // This delay gives the QR camera's dispose() a head start before routing
      // fires. CameraInputStream's retry backoff is a second layer of defense,
      // but avoiding the race entirely is cleaner and faster for the user.
      await Future.delayed(const Duration(milliseconds: 300));

      _orchestrator.advanceStep();
    } else {
      _retryCounter.increment();

      if (_retryCounter.hasExceededMax) {
        reset();
        _orchestrator.resetToHome();
      } else {
        // Failure state — scanner re-enabled by the screen watching this state.
        state = AsyncData(
          QRState(status: QRStatus.failure, errorMessage: result.errorMessage),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // reset — called on background reset, max retries, or successful submission
  // ---------------------------------------------------------------------------

  void reset() {
    state = const AsyncData(QRState(status: QRStatus.idle));
    _retryCounter.reset();
  }
}

final qrServiceProvider = Provider<QRService>((_) => QRService());

final qrNotifierProvider = AsyncNotifierProvider<QRNotifier, QRState>(
  QRNotifier.new,
);
