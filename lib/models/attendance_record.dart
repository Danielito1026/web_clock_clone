/// Payload sent to the backend on /api/attendance/submit.
///
/// [qrUuid] and [faceUuid] are nullable — they are omitted when the
/// corresponding verification step is not enabled in the pipeline config.
///
/// The backend handles all timestamping and time-in / time-out logic.
/// The client never generates or sends a timestamp.
class AttendanceRecord {
  final String eventType;   // 'time_in' | 'time_out'
  final String companyCode;
  final String username;
  final String password;    // included per architecture spec; memory only
  final String authToken;
  final String? qrUuid;     // null when QR step disabled
  final String? faceUuid;   // null when Face step disabled

  const AttendanceRecord({
    required this.eventType,
    required this.companyCode,
    required this.username,
    required this.password,
    required this.authToken,
    this.qrUuid,
    this.faceUuid,
  });

  Map<String, dynamic> toJson() => {
        'event_type': eventType,
        'company_code': companyCode,
        'username': username,
        'password': password,
        'auth_token': authToken,
        if (qrUuid != null) 'qr_uuid': qrUuid,
        if (faceUuid != null) 'face_uuid': faceUuid,
      };
}

/// Details returned by the backend after a successful submission.
/// Used to populate the ResultScreen.
class AttendanceRecordResult {
  final String eventType;
  final String username;
  final String companyCode;
  final String timestamp;   // server-generated; display only
  final String? message;    // optional human-readable confirmation from backend

  const AttendanceRecordResult({
    required this.eventType,
    required this.username,
    required this.companyCode,
    required this.timestamp,
    this.message,
  });

  factory AttendanceRecordResult.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordResult(
        eventType: json['event_type'] as String,
        username: json['username'] as String,
        companyCode: json['company_code'] as String,
        timestamp: json['timestamp'] as String,
        message: json['message'] as String?,
      );
}