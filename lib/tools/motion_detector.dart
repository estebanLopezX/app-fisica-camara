import 'dart:developer' as developer;
import 'dart:ui'; // Para Rect
import 'package:camera/camera.dart';

class MotionDetector {
  List<int>? _previousFrame;
  Rect? lastMotionRect;
  final List<Rect> motionHistory = [];
  int _frameSkip = 0;

  /// Detecta movimiento en tiempo real comparando frames de la cámara.
  Rect? processFrame(CameraImage image) {
    try {
      _frameSkip++;
      // Solo analiza 1 de cada 2 frames para reducir carga
      if (_frameSkip % 2 != 0) return null;

      final currentFrame = _convertToGrayscaleFromCameraImage(image);
      if (_previousFrame == null) {
        _previousFrame = currentFrame;
        developer.log(
          '🟡 Primer frame recibido (${currentFrame.length} píxeles)',
        );
        return null;
      }

      final width = image.width;
      final height = image.height;
      const int threshold = 8; // Diferencia mínima de pixel para considerarlo cambio
      const int minDiffPixels = 50; // Cantidad mínima de pixeles diferentes para detectar movimiento

      int minX = width, minY = height, maxX = 0, maxY = 0;
      int diffCount = 0;

      for (int i = 0; i < currentFrame.length; i++) {
        final diff = (currentFrame[i] - _previousFrame![i]).abs();
        if (diff > threshold) {
          final y = i ~/ width;
          final x = i % width;
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
          diffCount++;
        }
      }

      _previousFrame = currentFrame;

      if (diffCount > minDiffPixels) {
        final rect = Rect.fromLTRB(
          minX.toDouble(),
          minY.toDouble(),
          maxX.toDouble(),
          maxY.toDouble(),
        );
        motionHistory.add(rect);
        lastMotionRect = rect;
        developer.log("🟥 Movimiento detectado ($diffCount píxeles): $rect");
        return rect;
      }

      return null;
    } catch (e) {
      developer.log('❌ Error en processFrame: $e');
      return null;
    }
  }

  /// Convierte CameraImage a escala de grises usando el plano Y (luminancia)
  List<int> _convertToGrayscaleFromCameraImage(CameraImage image) {
    try {
      final yPlane = image.planes[0].bytes;
      return List<int>.from(yPlane);
    } catch (e) {
      developer.log('⚠️ Error convirtiendo CameraImage a escala de grises: $e');
      return <int>[];
    }
  }
}
