import 'package:flutter/material.dart';

class MotionPainter extends CustomPainter {
  final Rect motionRect;
  final Size cameraPreviewSize;

  MotionPainter(this.motionRect, {required this.cameraPreviewSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (motionRect == Rect.zero) return;

    // Escalado proporcional
    final scaleX = size.width / cameraPreviewSize.width;
    final scaleY = size.height / cameraPreviewSize.height;

    final scaledRect = Rect.fromLTRB(
      motionRect.left * scaleX,
      motionRect.top * scaleY,
      motionRect.right * scaleX,
      motionRect.bottom * scaleY,
    );

    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(scaledRect, paint);

    // Debug visual
    // print('🟥 Dibujando rect escalado: $scaledRect');
  }

  @override
  bool shouldRepaint(covariant MotionPainter oldDelegate) {
    return oldDelegate.motionRect != motionRect;
  }
}
