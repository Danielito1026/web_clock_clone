import 'package:dio/dio.dart';

class CancelTokenManager {
  final List<CancelToken> _tokens = [];

  /// Creates a new [CancelToken], tracks it, and returns it.
  /// Pass the returned token to every Dio request so it can be
  /// cancelled as a group on background or session reset.
  CancelToken generate() {
    final token = CancelToken();
    _tokens.add(token);
    return token;
  }

  /// Cancels every non-cancelled token and clears the list.
  /// Called by [AppLifecycleObserver] when the app is backgrounded.
  void cancelAll() {
    for (final token in _tokens) {
      if (!token.isCancelled) {
        token.cancel('session reset');
      }
    }
    _tokens.clear();
  }

  /// Clears all token references WITHOUT cancelling them.
  /// Called after a clean, successful submission — the requests
  /// already completed so there is nothing to cancel.
  void clear() {
    _tokens.clear();
  }
}
