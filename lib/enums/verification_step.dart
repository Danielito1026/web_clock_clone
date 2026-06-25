enum VerificationStep {
  login,
  qr,
  face;

  /// Human-readable label for debugging and error messages.
  String get label => switch (this) {
    VerificationStep.login => 'Login',
    VerificationStep.qr    => 'QR Scan',
    VerificationStep.face  => 'Face Liveness',
  };
}