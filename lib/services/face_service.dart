import 'dart:io';

import 'package:dio/dio.dart';

/// Result returned by [FaceService.registerSession].
class FaceResult {
  final bool isSuccess;
  final String? faceUuid;     // present on success
  final String? errorMessage; // present on failure

  const FaceResult.success({required this.faceUuid})
      : isSuccess = true,
        errorMessage = null;

  const FaceResult.failure({required String message})
      : isSuccess = false,
        faceUuid = null,
        errorMessage = message;
}

/// Handles the /api/face/session call.
/// Swap the body of [registerSession()] for real Dio/Retrofit logic once the API exists.
class FaceService {
  Future<FaceResult> registerSession({
    required String? authToken,
    required File? photo,
    required CancelToken cancelToken,
  }) async {
    // TODO: replace with real API call when backend is available.
    // POST /api/face/session
    // body: { auth_token }
    // file: photo (multipart if photo != null)
    //
    // Suggested Dio multipart pattern:
    //
    // final formData = FormData.fromMap({
    //   'auth_token': authToken,
    //   if (photo != null)
    //     'photo': await MultipartFile.fromFile(
    //       photo.path,
    //       filename: 'face_capture.jpg',
    //       contentType: DioMediaType('image', 'jpeg'),
    //     ),
    // });
    // final response = await dio.post(
    //   '/api/face/session',
    //   data: formData,
    //   cancelToken: cancelToken,
    // );
    // return FaceResult.success(faceUuid: response.data['face_uuid']);
    
    // This sample implementation returns a success for a known demo
    // auth token and a failure otherwise.
    await Future.delayed(const Duration(milliseconds: 400));

    // If caller provides the demo/sample auth token, return success.
    if (authToken == 'sample-auth-token-123456') {
      return const FaceResult.success(faceUuid: 'sample-face-uuid-abc123');
    }

    // Otherwise return a sample failure result.
    return const FaceResult.failure(
      message: 'Face session registration failed: invalid token or backend unavailable.',
    );
  }
}