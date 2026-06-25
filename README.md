# web_clock_clone

A Flutter attendance app clone with stubbed backend behavior for local testing.

## Demo Test Data

The app currently uses sample return values instead of a real backend. Use the following values to exercise the login, QR, face, and attendance submission flows.

### Login

- `companyCode`: `demo`
- `username`: `demo`
- `password`: `demodemo`

On success, the app returns a sample auth token:

- `authToken`: `sample-auth-token-123456`

### QR Validation

Scan a QR Code this with this content:
- `qrContent`: `zHh+awZ4RjjuRBSKo92mNQ==`

On success, the app returns the same QR UUID:

- `qrUuid`: `sample-auth-token-123456`

### Face Session

The face session stub accepts the demo auth token above and returns a sample face UUID.

- `authToken`: `sample-auth-token-123456`
- `faceUuid`: `sample-face-uuid-abc123`

### Attendance Submission

Use the same sample auth token for attendance submission.

- `authToken`: `sample-auth-token-123456`
- `eventType`: `time_in` or `time_out`

On success, the app returns a sample attendance record with a current timestamp and the message:

- `Sample submission accepted (demo).`

## Notes

The sample behavior is implemented in:

- `lib/services/login_service.dart`
- `lib/services/qr_service.dart`
- `lib/services/face_service.dart`
- `lib/services/attendance_service.dart`

Replace these stubs with real API calls once the backend is available.

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
