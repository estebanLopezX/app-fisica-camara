import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:parabola_detector/presentation/screen/video_uploader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:parabola_detector/tools/motion_detector.dart';
import 'package:parabola_detector/tools/motion_painter.dart';
import 'package:parabola_detector/presentation/screen/motion_results_screen.dart';

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
  final List<Rect> _motionRects = [];

  // ✅ Instancia del uploader (usa la IP del PC donde corre server.py)
  late final VideoUploader uploader = VideoUploader(
    serverUrl: 'http://192.168.1.8:8000',
  );

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Se necesitan permisos de cámara y micrófono"),
        ),
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _controller!.initialize();

      await _controller!.startImageStream((CameraImage image) {
        final rect = _motionDetector.processFrame(image);
        if (rect != null && mounted) {
          setState(() {
            _motionRect = rect;
            _motionRects.add(rect);
          });
          debugPrint("📦 Movimiento detectado: $_motionRect");
        }
      });

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('❌ Error al inicializar la cámara: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      try {
        final XFile videoFile = await _controller!.stopVideoRecording();
        _timer?.cancel();
        setState(() {
          _isRecording = false;
          _recordDuration = 0;
        });

        // 📂 Guardar video localmente
        final directory = Directory(
          '/storage/emulated/0/DCIM/ParabolaDetector',
        );
        if (!directory.existsSync()) directory.createSync(recursive: true);

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final savedPath = '${directory.path}/ParabolaDetector_$timestamp.mp4';
        await File(videoFile.path).copy(savedPath);

        // 📲 Actualizar galería Android
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$savedPath',
        ]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Video guardado en: $savedPath")),
        );

        // 🚀 Enviar video al servidor Python
        await uploader.sendVideo(File(savedPath));

        // 🧠 Mostrar resultados si hay movimientos detectados
        if (_motionRects.isNotEmpty) {
          final width = _controller!.value.previewSize?.width ?? 640;
          final height = _controller!.value.previewSize?.height ?? 480;

          final validRects = _motionRects
              .where(
                (r) =>
                    r.width > 10 &&
                    r.height > 10 &&
                    r.width < width * 0.95 &&
                    r.height < height * 0.95,
              )
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MotionResultsScreen.fromCamera(
                motionRects: validRects,
                controller: _controller!,
                fps: 30.0,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "⚠️ No se detectaron movimientos durante la grabación",
              ),
            ),
          );
        }

        _motionRects.clear();
        _motionDetector.motionHistory.clear();
      } catch (e) {
        debugPrint("❌ Error al detener la grabación: $e");
      }
    } else {
      try {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
        _startTimer();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🎬 Grabando...")));
      } catch (e) {
        debugPrint("❌ Error al iniciar la grabación: $e");
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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

          if (_isRecording)
            Positioned(
              top: 50,
              right: 20,
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_recordDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
