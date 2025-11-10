import 'package:camera/camera.dart';

class FrameUtils {
  static MotionDiff calculateDifference(CameraImage prev, CameraImage current) {
    // Aquí conviertes a formato gris y comparas intensidades
    // Devuelves un objeto con información del movimiento detectado
    return MotionDiff(hasMovement: true, centerX: 100, centerY: 200);
  }
}

class MotionDiff {
  final bool hasMovement;
  final double centerX;
  final double centerY;
  MotionDiff({
    required this.hasMovement,
    required this.centerX,
    required this.centerY,
  });
}
