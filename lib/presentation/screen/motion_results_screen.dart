import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:parabola_detector/tools/video_screen_preview.dart';

// MotionResultsWithParabola.dart
// Pantalla que dibuja rects (overlay) y además una gráfica XY realista
// con origen en el suelo (abajo-izquierda) y ajuste parabólico (y = ax^2 + bx + c).
// Requiere que le pases rects en coordenadas de pixels (misma referencia que frameWidth/frameHeight)
// y un factor pxToMeters para convertir a metros reales.

class MotionResultsWithParabola extends StatelessWidget {
  final List<Rect> rects; // rects en coordenadas de imagen (px)
  final double frameWidth; // ancho de la imagen en px (ej: 1920.0)
  final double frameHeight; // alto de la imagen en px (ej: 1080.0)
  final double fps;
  final double pxToMeters; // metros por pixel

  const MotionResultsWithParabola({
    super.key,
    required this.rects,
    required this.frameWidth,
    required this.frameHeight,
    required this.pxToMeters,
    this.fps = 30.0,
  });

  /// Factory para crear desde controller (similar a tu clase anterior)
  factory MotionResultsWithParabola.fromCamera({
    required List<Rect> motionRects,
    required CameraController controller,
    required double pxToMeters,
    double fps = 30.0,
  }) {
    final width = controller.value.previewSize?.width ?? 640;
    final height = controller.value.previewSize?.height ?? 480;
    return MotionResultsWithParabola(
      rects: List.from(motionRects),
      frameWidth: width,
      frameHeight: height,
      pxToMeters: pxToMeters,
      fps: fps,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convertir rects a centros en px
    final centersPx = rects
        .map((r) => Offset((r.left + r.right) / 2, (r.top + r.bottom) / 2))
        .toList();

    // Convertir a metros y ajustar sistema de coordenadas: origen abajo-izquierda
    final List<Offset> centersM = centersPx.map((p) {
      final mx = p.dx * pxToMeters; // x en metros desde izquierda
      // en imagen Y aumenta hacia abajo; en coordenadas físicas queremos Y hacia arriba desde suelo
      // asumimos que el suelo corresponde a y = frameHeight (parte inferior del frame)
      final yFromBottomPx = frameHeight - p.dy;
      final my = yFromBottomPx * pxToMeters; // metros desde suelo
      return Offset(mx, my);
    }).toList();

    // Ajuste parabólico y métricas físicas
    final ParabolaFitResult fit = ParabolaFit.fit(centersM);

    // Preparar resumen físico
    final double totalTime = (centersM.length - 1) / fps;
    final double totalDistanceM = _totalDistance(centersM);
    final double avgSpeed = totalTime > 0 ? totalDistanceM / totalTime : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados y trayectoria (física)'),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Panel superior: preview overlay (normalized drawing)
            Expanded(
              flex: 5,
              child: Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      return CustomPaint(
                        painter: OverlayPainter(
                          rects: rects,
                          frameWidth: frameWidth,
                          frameHeight: frameHeight,
                        ),
                        child: Container(),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Panel inferior: gráfico físico XY con origen en suelo
            Expanded(
              flex: 5,
              child: Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // eje Y con labels
                      SizedBox(
                        width: 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('m', style: TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(
                              '${(fit.maxY).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '0.00',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Grafico
                      Expanded(
                        child: PhysicalPlot(
                          points: centersM,
                          fit: fit,
                          pxToMeters: pxToMeters,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos físicos:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tiempo total (estimado): ${totalTime.toStringAsFixed(2)} s',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Distancia total (trayectoria): ${totalDistanceM.toStringAsFixed(3)} m',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Velocidad promedio: ${avgSpeed.toStringAsFixed(3)} m/s',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ajuste parabólico: y = a·x² + b·x + c',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'a = ${fit.a.toStringAsExponential(3)}, b = ${fit.b.toStringAsExponential(3)}, c = ${fit.c.toStringAsExponential(3)}',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPreviewPage(
                      videoUrl:
                          'http://127.0.0.1:8000/videos/ParabolaDetector_1763419529647.mp4',
                    ),
                  ),
                );
              },
              child: const Text('Ver video con tracking'),
            ),
          ],
        ),
      ),
    );
  }

  static double _totalDistance(List<Offset> pts) {
    double sum = 0.0;
    for (int i = 1; i < pts.length; i++) {
      sum += (pts[i] - pts[i - 1]).distance;
    }
    return sum;
  }
}

/// Painter que dibuja rectángulos normalizados (preview overlay)
class OverlayPainter extends CustomPainter {
  final List<Rect> rects;
  final double frameWidth;
  final double frameHeight;

  OverlayPainter({
    required this.rects,
    required this.frameWidth,
    required this.frameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final fill = Paint()
      ..color = Colors.redAccent.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (final r in rects) {
      final normalized = Rect.fromLTRB(
        r.left / frameWidth * size.width,
        r.top / frameHeight * size.height,
        r.right / frameWidth * size.width,
        r.bottom / frameHeight * size.height,
      );
      canvas.drawRect(normalized, fill);
      canvas.drawRect(normalized, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget que dibuja la gráfica física (XY), origen abajo-izquierda
class PhysicalPlot extends StatelessWidget {
  final List<Offset> points; // en metros
  final ParabolaFitResult fit;
  final double pxToMeters;

  const PhysicalPlot({
    super.key,
    required this.points,
    required this.fit,
    required this.pxToMeters,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return CustomPaint(
          painter: PhysicalPlotPainter(points: points, fit: fit),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class PhysicalPlotPainter extends CustomPainter {
  final List<Offset> points; // metros
  final ParabolaFitResult fit;

  PhysicalPlotPainter({required this.points, required this.fit});

  @override
  void paint(Canvas canvas, Size size) {
    // calcular rangos
    final double maxX = _maxX(points);
    final double maxY = math.max(fit.maxY, _maxY(points));

    final double pad = 10.0;
    final double plotW = size.width - pad * 2;
    final double plotH = size.height - pad * 2;

    // fondo
    final bg = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // ejes
    final axis = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.0;
    // X axis (bottom)
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(size.width - pad, size.height - pad),
      axis,
    );
    // Y axis (left)
    canvas.drawLine(Offset(pad, pad), Offset(pad, size.height - pad), axis);

    // dibujar puntos (convertir metros -> pixel dentro del plot)
    final pointPaint = Paint()..color = Colors.orangeAccent;
    for (final p in points) {
      final px = pad + (p.dx / (maxX == 0 ? 1 : maxX)) * plotW;
      final py =
          size.height -
          pad -
          (p.dy / (maxY == 0 ? 1 : maxY)) * plotH; // invertir Y
      canvas.drawCircle(Offset(px, py), 4, pointPaint);
    }

    // dibujar curva parabólica (muestra en rango X)
    final curvePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final steps = 200;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * maxX;
      final y = fit.eval(x);
      final px = pad + (x / (maxX == 0 ? 1 : maxX)) * plotW;
      final py = size.height - pad - (y / (maxY == 0 ? 1 : maxY)) * plotH;
      if (i == 0)
        path.moveTo(px, py);
      else
        path.lineTo(px, py);
    }
    canvas.drawPath(path, curvePaint);

    // dibujar etiquetas simples
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '0.0',
      style: TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        pad - textPainter.width - 4,
        size.height - pad - textPainter.height / 2,
      ),
    );

    textPainter.text = TextSpan(
      text: '${maxY.toStringAsFixed(2)} m',
      style: TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pad - textPainter.width - 4, pad - textPainter.height / 2),
    );

    textPainter.text = TextSpan(
      text: '${maxX.toStringAsFixed(2)} m',
      style: TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - pad - textPainter.width, size.height - pad + 4),
    );
  }

  double _maxX(List<Offset> pts) {
    if (pts.isEmpty) return 1.0;
    double m = 0.0;
    for (final p in pts) if (p.dx > m) m = p.dx;
    return m;
  }

  double _maxY(List<Offset> pts) {
    if (pts.isEmpty) return 1.0;
    double m = 0.0;
    for (final p in pts) if (p.dy > m) m = p.dy;
    return m;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Pequeña implementación de ajuste parabólico (mínimos cuadrados)
class ParabolaFitResult {
  final double a;
  final double b;
  final double c;
  final double maxY;
  ParabolaFitResult({
    required this.a,
    required this.b,
    required this.c,
    required this.maxY,
  });

  double eval(double x) => a * x * x + b * x + c;

  static ParabolaFitResult zero() =>
      ParabolaFitResult(a: 0, b: 0, c: 0, maxY: 0);
}

class ParabolaFit {
  /// Ajusta y = a x^2 + b x + c a los puntos (x,y) usando mínimos cuadrados.
  /// points deben estar en unidades físicas (metros).
  static ParabolaFitResult fit(List<Offset> points) {
    if (points.length < 3) return ParabolaFitResult.zero();

    final n = points.length;
    double sX = 0, sX2 = 0, sX3 = 0, sX4 = 0;
    double sY = 0, sXY = 0, sX2Y = 0;

    for (final p in points) {
      final x = p.dx;
      final y = p.dy;
      final x2 = x * x;
      final x3 = x2 * x;
      final x4 = x2 * x2;
      sX += x;
      sX2 += x2;
      sX3 += x3;
      sX4 += x4;
      sY += y;
      sXY += x * y;
      sX2Y += x2 * y;
    }

    // matriz normal (3x3) y vector RHS
    // [n    sX   sX2 ] [c]   [sY]
    // [sX   sX2  sX3 ] [b] = [sXY]
    // [sX2  sX3  sX4 ] [a]   [sX2Y]

    final m00 = n.toDouble();
    final m01 = sX;
    final m02 = sX2;
    final m10 = sX;
    final m11 = sX2;
    final m12 = sX3;
    final m20 = sX2;
    final m21 = sX3;
    final m22 = sX4;

    final rhs0 = sY;
    final rhs1 = sXY;
    final rhs2 = sX2Y;

    // resolver sistema 3x3 con regla de Cramer o inversa manual
    final det = _det3(m00, m01, m02, m10, m11, m12, m20, m21, m22);
    if (det.abs() < 1e-12) return ParabolaFitResult.zero();

    final detC = _det3(rhs0, m01, m02, rhs1, m11, m12, rhs2, m21, m22);
    final detB = _det3(m00, rhs0, m02, m10, rhs1, m12, m20, rhs2, m22);
    final detA = _det3(m00, m01, rhs0, m10, m11, rhs1, m20, m21, rhs2);

    final a = detA / det;
    final b = detB / det;
    final c = detC / det;

    // calcula maxY estimado en el rango de los puntos
    double maxY = 0.0;
    for (final p in points) {
      final y = a * p.dx * p.dx + b * p.dx + c;
      if (y > maxY) maxY = y;
    }

    return ParabolaFitResult(a: a, b: b, c: c, maxY: maxY);
  }

  static double _det3(
    double a00,
    double a01,
    double a02,
    double a10,
    double a11,
    double a12,
    double a20,
    double a21,
    double a22,
  ) {
    return a00 * (a11 * a22 - a12 * a21) -
        a01 * (a10 * a22 - a12 * a20) +
        a02 * (a10 * a21 - a11 * a20);
  }
}
