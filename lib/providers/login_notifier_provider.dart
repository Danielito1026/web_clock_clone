import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_clock_clone/config/verfication_orchestrator.dart';
import 'package:web_clock_clone/providers/orchestrator_provider.dart';
import 'package:web_clock_clone/services/login_service.dart';
import 'package:web_clock_clone/utils/retry_counter.dart';

enum LoginStatus { idle, loading, success, failure }

class LoginState {
  final String? companyCode;
  final String? username;

  /// Held in memory only — never written to disk or secure storage.
  /// Flushed in [flushCredentials()] on successful submission or max retries.
  final String? password;

  final String? authToken;
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({
    this.companyCode,
    this.username,
    this.password,
    this.authToken,
    this.status = LoginStatus.idle,
    this.errorMessage,
  });

  LoginState copyWith({
    String? companyCode,
    String? username,
    String? password,
    String? authToken,
    LoginStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      companyCode: companyCode ?? this.companyCode,
      username: username ?? this.username,
      password: password ?? this.password,
      authToken: authToken ?? this.authToken,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LoginNotifier extends AsyncNotifier<LoginState> {
  final _retryCounter = RetryCounter();

  // Lazily accessed — not injected — to keep the notifier easy to test.
  LoginService get _repository => ref.read(loginServiceProvider);
  VerificationOrchestrator get _orchestrator =>
      ref.read(verificationOrchestratorProvider.notifier);
  FlutterSecureStorage get _secureStorage => ref.read(secureStorageProvider);

  @override
  Future<LoginState> build() async =>
      const LoginState(status: LoginStatus.idle);

  // ---------------------------------------------------------------------------
  // Exposed for the login screen — "X attempts remaining"
  // ---------------------------------------------------------------------------

  int get attemptsRemaining => RetryCounter.maxAttempts - _retryCounter.count;

  // ---------------------------------------------------------------------------
  // submit — called by LoginScreen on form submit
  // ---------------------------------------------------------------------------

  Future<void> submit(
    String companyCode,
    String username,
    String password, {
    void Function()? onMaxRetriesExceeded,
  }) async {
    state = const AsyncLoading();

    final cancelToken = _orchestrator.cancelTokenManager.generate();

    final result = await _repository.login(
      companyCode: companyCode,
      username: username,
      password: password,
      cancelToken: cancelToken,
    );

    if (result.isSuccess) {
      // Write auth token to secure storage (Keychain / Keystore).
      // Password stays in memory only — written to state, never to disk.
      await _secureStorage.write(key: 'auth_token', value: result.authToken);

      state = AsyncData(
        LoginState(
          companyCode: companyCode,
          username: username,
          password: password, // memory only
          authToken: result.authToken,
          status: LoginStatus.success,
        ),
      );

      _orchestrator.advanceStep();
    } else {
      _retryCounter.increment();

      if (_retryCounter.hasExceededMax) {
        // Full pipeline reset — flushes credentials then routes to home.
        await flushCredentials();
        // Notify the caller (UI) so it can reset its form key / fields.
        try {
          onMaxRetriesExceeded?.call();
        } catch (_) {
          // Swallow UI callback errors; notifier shouldn't crash because of UI code.
        }
        _orchestrator.resetToHome();
      } else {
        state = AsyncData(
          LoginState(
            status: LoginStatus.failure,
            errorMessage: result.errorMessage,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // flushCredentials — called on max retries OR successful final submission
  // Deletes auth token from secure storage and clears all state.
  // ---------------------------------------------------------------------------

  Future<void> flushCredentials() async {
    await _secureStorage.delete(key: 'auth_token');
    state = const AsyncData(LoginState(status: LoginStatus.idle));
    _retryCounter.reset();
  }

  // ---------------------------------------------------------------------------
  // resetForBackground — called when orchestrator.resetToFirstStep() fires
  // Clears the form so the employee re-enters credentials on resume.
  // Does NOT delete the auth token — session was interrupted, not failed.
  // ---------------------------------------------------------------------------

  void resetForBackground() {
    state = const AsyncData(LoginState(status: LoginStatus.idle));
    _retryCounter.reset();
  }
}

final loginServiceProvider = Provider<LoginService>((_) => LoginService());

final loginNotifierProvider = AsyncNotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);
