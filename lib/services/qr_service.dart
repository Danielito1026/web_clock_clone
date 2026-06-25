import 'package:dio/dio.dart';

/// Result returned by [QRService.validate].
class QRResult {
  final bool isSuccess;
  final String? qrUuid;       // present on success
  final String? errorMessage; // present on failure

  const QRResult.success({required this.qrUuid})
      : isSuccess = true,
        errorMessage = null;

  const QRResult.failure({required String message})
      : isSuccess = false,
        qrUuid = null,
        errorMessage = message;
}

/// Handles the /api/qr/validate call.
/// Swap the body of [validate()] for real Dio/Retrofit logic once the API exists.
class QRService {
  Future<QRResult> validate({
    required String qrContent,
    required String? authToken,
    required CancelToken cancelToken,
  }) async {
    // TODO: replace with real API call when backend is available.
    // This sample implementation returns a success for a known demo
    // QR content and a failure otherwise.
    await Future.delayed(const Duration(milliseconds: 400));

    // Known demo QR -> success
    if (qrContent == 'zHh+awZ4RjjuRBSKo92mNQ==') {
      return const QRResult.success(qrUuid: 'sample-auth-token-123456');
    }

    // Otherwise return a sample failure result.
    return const QRResult.failure(
      message: 'QR validation failed: invalid code or backend unavailable.',
    );
  }
}