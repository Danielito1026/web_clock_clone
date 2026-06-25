import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionStatus {
  granted,
  denied, // soft denial — can re-request
  permanentlyDenied, // must open device settings
}

class PermissionHelper {
  PermissionHelper._(); // prevent instantiation

  static Future<CameraPermissionStatus> checkCamera() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return CameraPermissionStatus.granted;
    }

    final result = await Permission.camera.request();

    if (result.isGranted) {
      return CameraPermissionStatus.granted;
    }
    if (result.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    return CameraPermissionStatus.denied;
  }
}