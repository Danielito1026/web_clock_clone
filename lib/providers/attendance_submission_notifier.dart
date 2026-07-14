import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/config/verfication_orchestrator.dart';
import 'package:web_clock_clone/models/attendance_record.dart';
import 'package:web_clock_clone/providers/face_notifier.dart';
import 'package:web_clock_clone/providers/home_notifier_provider.dart';
import 'package:web_clock_clone/providers/login_notifier_provider.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';
import 'package:web_clock_clone/providers/qr_notifier.dart';
import 'package:web_clock_clone/services/attendance_service.dart';

class AttendanceSubmissionNotifier
    extends AsyncNotifier<AttendanceRecordResult?> {
  /// Guards against concurrent submissions (e.g. button double-tap).
  /// Reset to false in both success and failure paths — no path can leave
  /// this stuck at true.
  bool _isSubmitting = false;

  AttendanceService get _repository => ref.read(attendanceServiceProvider);
  VerificationOrchestrator get _orchestrator =>
      ref.read(verificationOrchestratorProvider.notifier);

  @override
  Future<AttendanceRecordResult?> build() async => null;

  // ---------------------------------------------------------------------------
  // submit — called by the last active step screen once all steps are passed,
  // or wired to trigger automatically from the orchestrator's advanceStep().
  // ---------------------------------------------------------------------------

  Future<void> submit() async {
    // 1. Concurrent submission guard — double-tap protection.
    if (_isSubmitting) return;

    // 2. Connectivity check before touching anything.
    final connectivity = ref.read(connectivityProvider);
    final isOffline =
        connectivity
            .whenData(
              (results) =>
                  results.contains(ConnectivityResult.none) || results.isEmpty,
            )
            .value ??
        true; // default to offline if stream hasn't emitted yet

    if (isOffline) {
      state = AsyncError(
        'No internet connection. Please check your network and try again.',
        StackTrace.current,
      );
      return;
    }

    // 3. Assemble payload from all step notifiers.
    //    qrState and faceState are nullable — null when the step was disabled.
    final homeState = ref.read(homeNotifierProvider);
    final loginState = ref.read(loginNotifierProvider).value;
    final qrState = ref.read(qrNotifierProvider).value;
    final faceState = ref.read(faceNotifierProvider).value;
    final authToken = await ref
        .read(secureStorageProvider)
        .read(key: 'auth_token');

    // Guard: loginState must be present — Login step is always active when
    // submission is reached (even Login-only config sets loginState).
    if (loginState == null ||
        homeState.companyCode.isEmpty ||
        loginState.username == null ||
        loginState.password == null ||
        authToken == null) {
      state = AsyncError(
        'Session data is incomplete. Please restart the verification.',
        StackTrace.current,
      );
      return;
    }

    final payload = AttendanceRecord(
      eventType: homeState.selectedEventType.value,
      companyCode: homeState.companyCode,
      username: loginState.username!,
      password: loginState.password!, // memory only; per architecture spec
      authToken: authToken,
      qrUuid: qrState?.qrUuid, // null when QR step not enabled
      faceUuid: faceState?.faceUuid, // null when Face step not enabled
    );

    // 4. Mark submitting and enter loading state.
    _isSubmitting = true;
    state = const AsyncLoading();

    final cancelToken = _orchestrator.cancelTokenManager.generate();
    final result = await _repository.submit(
      payload: payload,
      cancelToken: cancelToken,
    );

    // 5a. Success — flush all sensitive state then advance orchestrator.
    if (result.isSuccess) {
      _isSubmitting = false;

      // Flush credentials and step UUIDs immediately after successful submit.
      // Order: login (async — deletes secure storage) first, then sync resets.
      await ref.read(loginNotifierProvider.notifier).flushCredentials();
      ref.read(qrNotifierProvider.notifier).reset();
      ref.read(faceNotifierProvider.notifier).reset();
      ref.read(homeNotifierProvider.notifier).reset();

      // clear() — not cancelAll() — tokens already completed successfully.
      _orchestrator.cancelTokenManager.clear();

      state = AsyncData(result.attendanceRecord);

      // Advances the orchestrator past its last step → isComplete becomes true
      // → go_router redirect fires → navigates to /result.
      _orchestrator.advanceStep();
    } else {
      // 5b. Failure — do NOT flush credentials; user can retry submission.
      _isSubmitting = false;
      state = AsyncError(
        result.errorMessage ?? 'Submission failed. Please try again.',
        StackTrace.current,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // reset — called if the user navigates back from the result screen, or
  // if a new pipeline session starts. Clears the last result from state.
  // ---------------------------------------------------------------------------

  void reset() {
    _isSubmitting = false;
    state = const AsyncData(null);
  }
}

final attendanceServiceProvider = Provider<AttendanceService>(
  (_) => AttendanceService(),
);

final attendanceSubmissionProvider =
    AsyncNotifierProvider<
      AttendanceSubmissionNotifier,
      AttendanceRecordResult?
    >(AttendanceSubmissionNotifier.new);
