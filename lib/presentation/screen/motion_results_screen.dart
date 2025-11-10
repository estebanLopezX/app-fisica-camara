import 'package:flutter/material.dart';
import 'dart:ui';

class MotionResultsScreen extends StatelessWidget {
  final List<Rect> rects;

  const MotionResultsScreen({super.key, required this.rects});

  @override
  Widget build(BuildContext context) {
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
                        aspectRatio: 3 / 4,
                        child: CustomPaint(
                          painter: MotionResultsPainter(rects),
                          child: Container(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
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
                          "🧠 Análisis básico:",
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _analyzeMovements(rects),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 🔍 Analiza posiciones promedio y da un resumen textual
  static String _analyzeMovements(List<Rect> rects) {
    if (rects.isEmpty) return "Sin datos.";

    double avgX = 0;
    double avgY = 0;

    for (final rect in rects) {
      avgX += (rect.left + rect.right) / 2;
      avgY += (rect.top + rect.bottom) / 2;
    }

    avgX /= rects.length;
    avgY /= rects.length;

    String horizontal =
        (avgX < 300) ? "izquierda" : (avgX > 700) ? "derecha" : "centro";
    String vertical =
        (avgY < 400) ? "parte superior" : (avgY > 800) ? "parte inferior" : "zona media";

    return "El movimiento promedio ocurrió en la $vertical hacia la $horizontal.";
  }
}

class MotionResultsPainter extends CustomPainter {
  final List<Rect> rects;

  MotionResultsPainter(this.rects);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final highlight = Paint()
      ..color = Colors.redAccent.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Normalizamos las coordenadas a la vista
    for (final rect in rects) {
      final normalized = Rect.fromLTRB(
        rect.left / 1080 * size.width, // suponiendo cámara 1080p
        rect.top / 1920 * size.height,
        rect.right / 1080 * size.width,
        rect.bottom / 1920 * size.height,
      );

      canvas.drawRect(normalized, highlight);
      canvas.drawRect(normalized, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
