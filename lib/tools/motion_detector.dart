import 'dart:developer' as developer;
import 'dart:ui';
import 'package:camera/camera.dart';

class MotionDetector {
  List<int>? _previousFrame;
  Rect? lastMotionRect;
  final List<Rect> motionHistory = [];
  int _frameSkip = 0;

  /// Analiza un frame y retorna una región de movimiento si la hay
  Rect? processFrame(CameraImage image) {
    try {
      // 🔹 Procesar solo 1 de cada 2 frames (rendimiento)
      _frameSkip++;
      if (_frameSkip % 2 != 0) return null;

      final currentFrame = _convertToGrayscaleFromCameraImage(image);
      if (currentFrame.isEmpty) {
        developer.log('⚠️ Frame vacío o formato no soportado');
        return null;
      }

      // Primer frame → solo lo almacenamos como referencia
      if (_previousFrame == null) {
        _previousFrame = currentFrame;
        developer.log(
          '🟡 Primer frame inicializado (${currentFrame.length} píxeles)',
        );
        return null;
      }

      final width = image.width;
      final height = image.height;

      // 🔧 Sensibilidad (ajusta según tus pruebas)
      const int threshold = 15; // diferencia mínima entre píxeles
      const int minDiffPixels = 600; // número mínimo de píxeles diferentes

      int minX = width, minY = height, maxX = 0, maxY = 0;
      int diffCount = 0;

      // 🔸 Recorremos parcialmente la imagen (saltos de 2 píxeles)
      for (int y = 0; y < height; y += 2) {
        for (int x = 0; x < width; x += 2) {
          int i = y * width + x;
          final diff = (currentFrame[i] - _previousFrame![i]).abs();

          if (diff > threshold) {
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
            diffCount++;
          }
        }
      }

      _previousFrame = currentFrame;

      // 🔹 Detectar región de movimiento
      if (diffCount > minDiffPixels) {
        const double padding = 25.0;
        final rect = Rect.fromLTRB(
          (minX - padding).clamp(0, width).toDouble(),
          (minY - padding).clamp(0, height).toDouble(),
          (maxX + padding).clamp(0, width).toDouble(),
          (maxY + padding).clamp(0, height).toDouble(),
        );

        motionHistory.add(rect);
        lastMotionRect = rect;

        developer.log("🟥 Movimiento detectado: $diffCount píxeles → $rect");
        return rect;
      } else {
        developer.log("🟦 Sin movimiento significativo ($diffCount píxeles)");
        return null;
      }
    } catch (e) {
      developer.log('❌ Error en processFrame: $e');
      return null;
    }
  }

  /// Convierte la imagen a escala de grises (para comparar luminancia)
  List<int> _convertToGrayscaleFromCameraImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        // plano Y contiene la luminancia, ideal para movimiento
        return List<int>.from(image.planes[0].bytes);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        final bytes = image.planes[0].bytes;
        final gray = List<int>.generate(bytes.length ~/ 4, (i) {
          final b = bytes[i * 4];
          final g = bytes[i * 4 + 1];
          final r = bytes[i * 4 + 2];
          return ((0.299 * r) + (0.587 * g) + (0.114 * b)).toInt();
        });
        return gray;
      } else {
        developer.log('⚠️ Formato no soportado: ${image.format.group}');
        return <int>[];
      }
    } catch (e) {
      developer.log('⚠️ Error convirtiendo a escala de grises: $e');
      return <int>[];
    }
  }
}
