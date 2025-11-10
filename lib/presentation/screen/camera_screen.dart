import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:parabola_detector/presentation/screen/motion_results_screen.dart';
import 'package:parabola_detector/tools/motion_detector.dart';
import 'package:parabola_detector/tools/motion_painter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart'; // 👈 opcional si luego analizas video

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

  Rect? _motionRect;

  late MotionDetector _motionDetector;

  @override
  void initState() {
    super.initState();
    _motionDetector = MotionDetector();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Se necesitan permisos de cámara y micrófono"),
          ),
        );
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No se encontraron cámaras disponibles");
      }

      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _controller!.initialize();

      // 🔹 Activar análisis de frames en tiempo real
      await _controller!.startImageStream((CameraImage image) {
        final rect = _motionDetector.processFrame(image);
        if (rect != null && mounted) {
          setState(() {
            _motionRect = rect;
          });
        }
      });

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('❌ Error al inicializar la cámara: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      try {
        final XFile videoFile = await _controller!.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _timer?.cancel();
          _recordDuration = 0;
        });

        final directory = Directory(
          '/storage/emulated/0/DCIM/ParabolaDetector',
        );
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final savedPath = '${directory.path}/ParabolaDetector_$timestamp.mp4';

        await File(videoFile.path).copy(savedPath);

        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$savedPath',
        ]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Video guardado en: $savedPath")),
          );
        }

        debugPrint("✅ Video guardado en galería: $savedPath");

        // 🧠 Aquí podrías analizar el video si agregas soporte luego
        debugPrint("🧠 Análisis de movimiento completado.");

        // 👇 Muestra la pantalla de resultados con el historial detectado
        final motionRects = _motionDetector.motionHistory;

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MotionResultsScreen(rects: motionRects),
            ),
          );
          _motionDetector.motionHistory.clear();
        }
      } catch (e) {
        debugPrint("❌ Error al detener o guardar el video: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Error guardando el video")),
          );
        }
      }
    } else {
      try {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
        _startTimer();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("🎬 Grabando...")));
        }
      } catch (e) {
        debugPrint("❌ Error al iniciar la grabación: $e");
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
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
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

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

          const Positioned(
            top: 50,
            left: 20,
            child: Text(
              "Cámara activa",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ),

          if (_isRecording)
            Positioned(
              top: 50,
              right: 20,
              child: Row(
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_recordDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
                onPressed: _toggleRecording,
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
