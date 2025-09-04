import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ppg_analyzer.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final PPGAnalyzer _ppgAnalyzer = PPGAnalyzer();
  StreamController<Map<String, double?>>? _measurementController;
  Timer? _analysisTimer;
  bool _isAnalyzing = false;

  Stream<Map<String, double?>> get measurementStream =>
      _measurementController?.stream ?? const Stream.empty();

  Future<bool> initialize() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // Use back camera for PPG measurement
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Initialize camera controller
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _measurementController =
          StreamController<Map<String, double?>>.broadcast();

      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      return false;
    }
  }

  Future<void> startPPGAnalysis() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    if (_isAnalyzing) return;

    _isAnalyzing = true;
    _ppgAnalyzer.clearData();

    // Start camera preview
    await _controller!.startImageStream(_processImage);

    // Start periodic analysis
    _analysisTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _analyzeCurrentData();
    });
  }

  Future<void> stopPPGAnalysis() async {
    if (!_isAnalyzing) return;

    _isAnalyzing = false;
    _analysisTimer?.cancel();
    _analysisTimer = null;

    await _controller?.stopImageStream();
  }

  void _processImage(CameraImage image) {
    if (!_isAnalyzing) return;

    // Convert CameraImage to Uint8List for processing
    final imageData = _convertCameraImageToUint8List(image);

    // Add frame to PPG analyzer for real analysis
    _ppgAnalyzer.addFrame(imageData, image.width, image.height);
  }

  Uint8List _convertCameraImageToUint8List(CameraImage image) {
    // Convert YUV420 format to RGB
    final int width = image.width;
    final int height = image.height;

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    // Create RGB buffer
    final Uint8List rgb = Uint8List(width * height * 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final int yValue = image.planes[0].bytes[yIndex];
        final int uValue = image.planes[1].bytes[uvIndex];
        final int vValue = image.planes[2].bytes[uvIndex];

        // Convert YUV to RGB
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        final int rgbIndex = yIndex * 3;
        rgb[rgbIndex] = r; // Red
        rgb[rgbIndex + 1] = g; // Green
        rgb[rgbIndex + 2] = b; // Blue
      }
    }

    return rgb;
  }

  void _analyzeCurrentData() {
    if (!_ppgAnalyzer.hasEnoughData()) return;

    final measurements = <String, double?>{};

    // Calculate all health metrics
    measurements['heart_rate'] = _ppgAnalyzer.calculateHeartRate();

    final bloodPressure = _ppgAnalyzer.calculateBloodPressure();
    if (bloodPressure != null) {
      measurements['systolic'] = bloodPressure['systolic'];
      measurements['diastolic'] = bloodPressure['diastolic'];
    }

    measurements['hrv'] = _ppgAnalyzer.calculateHRV();
    measurements['spo2'] = _ppgAnalyzer.calculateSpO2();

    // Emit measurements
    _measurementController?.add(measurements);
  }

  Future<void> dispose() async {
    await stopPPGAnalysis();
    await _controller?.dispose();
    _measurementController?.close();
  }

  CameraController? get controller => _controller;
  bool get isAnalyzing => _isAnalyzing;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
}
