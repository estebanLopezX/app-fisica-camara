import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:camera/camera.dart';

class MotionResultsScreen extends StatelessWidget {
  final List<Rect> rects;
  final double frameWidth;
  final double frameHeight;
  final double fps;

  const MotionResultsScreen({
    super.key,
    required this.rects,
    required this.frameWidth,
    required this.frameHeight,
    this.fps = 30.0,
  });

  /// 🔹 Factory constructor para crear la pantalla desde un CameraController
  factory MotionResultsScreen.fromCamera({
    required List<Rect> motionRects,
    required CameraController controller,
    double fps = 30.0,
  }) {
    final width = controller.value.previewSize?.width ?? 640;
    final height = controller.value.previewSize?.height ?? 480;

    print(
      '🧩 [MotionResultsScreen] Factory constructor: ${motionRects.length} rects',
    );
    print('📏 FrameWidth: $width | FrameHeight: $height | FPS: $fps');

    return MotionResultsScreen(
      rects: List.from(motionRects),
      frameWidth: width,
      frameHeight: height,
      fps: fps,
    );
  }

  @override
  Widget build(BuildContext context) {
    print("🧩 [MotionResultsScreen] Iniciando con ${rects.length} rects.");
    for (int i = 0; i < rects.length; i++) {
      print("➡️ Rect #$i: ${rects[i]}");
    }
    print("📏 FrameWidth: $frameWidth | FrameHeight: $frameHeight | FPS: $fps");

    final analysis = _analyzeMovements(rects, fps: fps);

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Resultados del movimiento"),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: rects.isEmpty
            ? const Center(
                child: Text(
                  "❌ No se detectaron movimientos.",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: frameWidth / frameHeight,
                        child: CustomPaint(
                          painter: MotionResultsPainter(
                            rects: rects,
                            frameWidth: frameWidth,
                            frameHeight: frameHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(analysis),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard(String analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📦 Total de movimientos detectados: ${rects.length}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "🧠 Análisis completo:",
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            analysis,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  static String _analyzeMovements(List<Rect> rects, {required double fps}) {
    print(
      "🔎 [MotionResultsScreen] Iniciando análisis con ${rects.length} rects...",
    );

    if (rects.length < 2) {
      print("⚠️ No hay suficientes rectángulos para analizar.");
      return "Sin datos suficientes para el análisis.";
    }

    double totalDistance = 0;
    double maxSpeed = 0;
    double totalTime = (rects.length - 1) / fps;

    double sumX = 0;
    double sumY = 0;

    for (int i = 0; i < rects.length; i++) {
      final center = Offset(
        (rects[i].left + rects[i].right) / 2,
        (rects[i].top + rects[i].bottom) / 2,
      );
      sumX += center.dx;
      sumY += center.dy;
    }

    for (int i = 1; i < rects.length; i++) {
      final prevCenter = Offset(
        (rects[i - 1].left + rects[i - 1].right) / 2,
        (rects[i - 1].top + rects[i - 1].bottom) / 2,
      );
      final currCenter = Offset(
        (rects[i].left + rects[i].right) / 2,
        (rects[i].top + rects[i].bottom) / 2,
      );

      final distance = (currCenter - prevCenter).distance;
      totalDistance += distance;

      final speed = distance * fps;
      if (speed > maxSpeed) maxSpeed = speed;
    }

    final avgSpeed = totalDistance / totalTime;
    final avgCenter = Offset(sumX / rects.length, sumY / rects.length);

    print("📊 [Análisis completado]");
    print(" - Distancia total: ${totalDistance.toStringAsFixed(2)} px");
    print(" - Velocidad promedio: ${avgSpeed.toStringAsFixed(2)} px/s");
    print(" - Velocidad máxima: ${maxSpeed.toStringAsFixed(2)} px/s");
    print(" - Duración total: ${totalTime.toStringAsFixed(2)} s");
    print(
      " - Centro promedio: (${avgCenter.dx.toStringAsFixed(1)}, ${avgCenter.dy.toStringAsFixed(1)})",
    );

    return """
📏 Distancia total recorrida: ${totalDistance.toStringAsFixed(2)} px
⚡ Velocidad promedio: ${avgSpeed.toStringAsFixed(2)} px/s
🚀 Velocidad máxima: ${maxSpeed.toStringAsFixed(2)} px/s
⏱️ Duración total: ${totalTime.toStringAsFixed(2)} s
🎯 Centro promedio del movimiento: (${avgCenter.dx.toStringAsFixed(1)}, ${avgCenter.dy.toStringAsFixed(1)})
""";
  }
}

class MotionResultsPainter extends CustomPainter {
  final List<Rect> rects;
  final double frameWidth;
  final double frameHeight;

  MotionResultsPainter({
    required this.rects,
    required this.frameWidth,
    required this.frameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print("🎨 [MotionResultsPainter] Dibujando ${rects.length} rects...");

    final strokePaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fillPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (final rect in rects) {
      final normalized = Rect.fromLTRB(
        rect.left / frameWidth * size.width,
        rect.top / frameHeight * size.height,
        rect.right / frameWidth * size.width,
        rect.bottom / frameHeight * size.height,
      );

      print("🟥 Dibujando rect normalizado: $normalized");

      canvas.drawRect(normalized, fillPaint);
      canvas.drawRect(normalized, strokePaint);
    }

    final avgCenter = _calculateAvgCenter(rects, size);
    print("🟡 Centro promedio dibujado en: $avgCenter");
    canvas.drawCircle(avgCenter, 6, Paint()..color = Colors.yellowAccent);
  }

  Offset _calculateAvgCenter(List<Rect> rects, Size size) {
    double sumX = 0;
    double sumY = 0;
    for (final rect in rects) {
      final normalized = Rect.fromLTRB(
        rect.left / frameWidth * size.width,
        rect.top / frameHeight * size.height,
        rect.right / frameWidth * size.width,
        rect.bottom / frameHeight * size.height,
      );
      sumX += normalized.center.dx;
      sumY += normalized.center.dy;
    }
    return Offset(sumX / rects.length, sumY / rects.length);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
