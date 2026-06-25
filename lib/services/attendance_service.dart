import 'package:dio/dio.dart';
import 'package:web_clock_clone/models/attendance_record.dart';

/// Result returned by [AttendanceService.submit].
class SubmissionResult {
  final bool isSuccess;
  final AttendanceRecordResult? attendanceRecord; // present on success
  final String? errorMessage;                     // present on failure

  const SubmissionResult.success({required AttendanceRecordResult record})
      : isSuccess = true,
        attendanceRecord = record,
        errorMessage = null;

  const SubmissionResult.failure({required String message})
      : isSuccess = false,
        attendanceRecord = null,
        errorMessage = message;
}

/// Handles the /api/attendance/submit call.
/// Swap the body of [submit()] for real Dio/Retrofit logic once the API exists.
class AttendanceService {
  Future<SubmissionResult> submit({
    required AttendanceRecord payload,
    required CancelToken cancelToken,
  }) async {
    // TODO: replace with real API call when backend is available.
    // This sample implementation returns a success when the sample
    // auth token is provided and a failure otherwise.
    await Future.delayed(const Duration(milliseconds: 500));

    if (payload.authToken == 'sample-auth-token-123456') {
      final AttendanceRecordResult record = AttendanceRecordResult(
        eventType: payload.eventType,
        username: payload.username,
        companyCode: payload.companyCode,
        timestamp: DateTime.now().toIso8601String(),
        message: 'Sample submission accepted (demo).',
      );
      return SubmissionResult.success(record: record);
    }

    return const SubmissionResult.failure(
      message: 'Submission failed: invalid token or backend unavailable.',
    );
  }
}