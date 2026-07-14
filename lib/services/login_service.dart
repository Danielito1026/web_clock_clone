import 'package:dio/dio.dart';

/// Result returned by [LoginRepository.login].
class LoginResult {
  final bool isSuccess;
  final String? authToken; // present on success
  final String? errorMessage; // present on failure

  const LoginResult.success({required this.authToken})
    : isSuccess = true,
      errorMessage = null;

  const LoginResult.failure({required String message})
    : isSuccess = false,
      authToken = null,
      errorMessage = message;
}

/// Handles the /api/auth/login call.
/// Swap the body of [login()] for real Dio/Retrofit logic once the API exists.
class LoginService {
  Future<LoginResult> login({
    required String companyCode,
    required String username,
    required String password,
    required CancelToken cancelToken,
  }) async {
    // TODO: replace with real API call when backend is available.
    // This sample implementation returns a success for a known demo
    // credential set and a failure otherwise.
    await Future.delayed(const Duration(milliseconds: 500));

    // Example demo credentials -> success
    if (username == 'demo' && password == 'demodemo') {
      return const LoginResult.success(authToken: 'sample-auth-token-123456');
    }

    // Otherwise return a sample failure result.
    return const LoginResult.failure(
      message: 'Login failed: invalid credentials or backend unavailable.',
    );
  }
}
