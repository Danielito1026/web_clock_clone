class RetryCounter {
  static const int maxAttempts = 3;

  int _count = 0;

  int get count => _count;

  /// True when the number of attempts has reached [maxAttempts].
  /// Checked AFTER increment(), so the caller knows to trigger a reset.
  bool get hasExceededMax => _count >= maxAttempts;

  void increment() => _count++;

  void reset() => _count = 0;
}
