import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:parabola_detector/tools/motion_detector.dart';
import 'package:parabola_detector/tools/motion_painter.dart';
import 'package:parabola_detector/presentation/screen/motion_results_screen.dart';
import 'package:parabola_detector/presentation/screen/video_uploader.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isRecording = false;

  Timer? _timer;
  int _recordDuration = 0;

  late MotionDetector _motionDetector;
  Rect? _motionRect;

  // ⛔ YA NO USAMOS motionRects locales
  // final List<Rect> _motionRects = [];

  late final VideoUploader uploader = VideoUploader(
    serverUrl: 'http://192.168.1.8:8000',
  );

  List<Rect> serverRects = []; // ⬅️ AQUÍ GUARDAMOS RECTÁNGULOS DEL SERVER

  @override
  void initState() {
    super.initState();
    _motionDetector = MotionDetector();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final camPermission = await Permission.camera.request();
    final micPermission = await Permission.microphone.request();

    if (!camPermission.isGranted || !micPermission.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Se requieren permisos de cámara y micrófono"),
        ),
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _controller!.initialize();

      // 🔹 Stream para detectar movimiento visual local (solo para overlay)
      await _controller!.startImageStream((image) {
        final rect = _motionDetector.processFrame(image);
        if (rect != null && mounted) {
          setState(() {
            _motionRect = rect;
          });
        }
      });

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("❌ Error inicializando cámara: $e");
    }
  }

  Future<void> _toggleRecording() async {
    if (_controller == null) return;

    if (_isRecording) {
      // 🔴 DETENER GRABACIÓN
      try {
        XFile recorded = await _controller!.stopVideoRecording();
        _timer?.cancel();

        setState(() => _isRecording = false);

        final directory = Directory(
          '/storage/emulated/0/DCIM/ParabolaDetector',
        );
        if (!directory.existsSync()) directory.createSync(recursive: true);

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final savedPath = '${directory.path}/ParabolaDetector_$timestamp.mp4';

        await File(recorded.path).copy(savedPath);

        // 🔄 Actualizar galería
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$savedPath',
        ]);

        // 🚀 **ENVIAR VIDEO AL SERVIDOR**
        final response = await uploader.sendVideo(File(savedPath));

        if (response != null && response.containsKey("rects")) {
          print("🟢 Rectángulos recibidos del servidor:");
          print(response["rects"]);

          serverRects = [];

          for (var r in response["rects"]) {
            if (r.length == 4) {
              serverRects.add(
                Rect.fromLTWH(
                  r[0].toDouble(),
                  r[1].toDouble(),
                  r[2].toDouble(),
                  r[3].toDouble(),
                ),
              );
            }
          }
        }

        // 👉 SI HAY RECTÁNGULOS, IR A LA PANTALLA DE RESULTADOS
        if (serverRects.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MotionResultsScreen.fromCamera(
                motionRects: serverRects,
                controller: _controller!,
                fps: 30,
                pxToMeters: 0.0007436,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ No se detectaron movimientos.")),
          );
        }
      } catch (e) {
        debugPrint("❌ Error al detener grabación: $e");
      }
    } else {
      // 🟢 INICIAR GRABACIÓN
      try {
        await _controller!.startVideoRecording();
        setState(() => _isRecording = true);
        _startTimer();
      } catch (e) {
        debugPrint("❌ Error al iniciar grabación: $e");
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordDuration++);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          // 🔴 Dibujo del rect local
          if (_motionRect != null)
            Positioned.fill(
              child: CustomPaint(
                painter: MotionPainter(
                  _motionRect!,
                  cameraPreviewSize: Size(
                    _controller!.value.previewSize!.height,
                    _controller!.value.previewSize!.width,
                  ),
                ),
              ),
            ),

          // ❤️ Animación borde grabación
          if (_isRecording)
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red.withOpacity(
                    (_recordDuration % 2 == 0) ? 1.0 : 0.2,
                  ),
                  width: 6,
                ),
              ),
            ),

          // ⏱️ Temporizador
          if (_isRecording)
            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    "${(_recordDuration ~/ 60).toString().padLeft(2, '0')}:${(_recordDuration % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // 🎥 Botón grabar / parar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
                onPressed: _toggleRecording,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
