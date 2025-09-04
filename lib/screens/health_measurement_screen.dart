import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../providers/health_provider.dart';
import '../models/health_metric.dart';

class HealthMeasurementScreen extends StatefulWidget {
  final String type;

  const HealthMeasurementScreen({super.key, required this.type});

  @override
  State<HealthMeasurementScreen> createState() =>
      _HealthMeasurementScreenState();
}

class _HealthMeasurementScreenState extends State<HealthMeasurementScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;
  bool _isMeasuring = false;
  Map<String, double?> _currentMeasurements = {};
  String _statusMessage = 'Initializing camera...';
  int _remainingSeconds = 30;
  Timer? _measurementTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final success = await _cameraService.initialize();
      if (success) {
        setState(() {
          _isInitialized = true;
          _statusMessage = 'Place your finger on the back camera lens';
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to initialize camera';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _startMeasurement() async {
    if (!_isInitialized) return;

    setState(() {
      _isMeasuring = true;
      _remainingSeconds = 30;
      _statusMessage = 'Keep your finger steady on the back camera lens';
    });

    try {
      await _cameraService.startPPGAnalysis();

      // Listen to measurement updates
      _cameraService.measurementStream.listen((measurements) {
        setState(() {
          _currentMeasurements = measurements;
        });
      });

      // Start 30-second countdown timer
      _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            timer.cancel();
            _stopMeasurement();
          }
        });
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting measurement: $e';
        _isMeasuring = false;
      });
    }
  }

  Future<void> _stopMeasurement() async {
    if (!_isMeasuring) return;

    _measurementTimer?.cancel();
    _measurementTimer = null;

    setState(() {
      _isMeasuring = false;
      _statusMessage = 'Processing measurement...';
    });

    try {
      await _cameraService.stopPPGAnalysis();

      // Save the measurement
      await _saveMeasurement();

      setState(() {
        _statusMessage = 'Measurement completed!';
      });

      // Show results for 3 seconds before navigating back
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving measurement: $e';
      });
    }
  }

  Future<void> _saveMeasurement() async {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);

    switch (widget.type) {
      case 'heart_rate':
        if (_currentMeasurements['heart_rate'] != null) {
          await healthProvider.addHealthMetric(
            HealthMetric(
              id: 0, // Will be auto-generated
              type: 'heart_rate',
              value: _currentMeasurements['heart_rate']!,
              timestamp: DateTime.now(),
            ),
          );
        }
        break;
      case 'blood_pressure':
        if (_currentMeasurements['systolic'] != null &&
            _currentMeasurements['diastolic'] != null) {
          await healthProvider.addHealthMetric(
            HealthMetric(
              id: 0,
              type: 'blood_pressure',
              value: _currentMeasurements['systolic']!,
              secondaryValue: _currentMeasurements['diastolic']!.toString(),
              timestamp: DateTime.now(),
            ),
          );
        }
        break;
      case 'hrv':
        if (_currentMeasurements['hrv'] != null) {
          await healthProvider.addHealthMetric(
            HealthMetric(
              id: 0,
              type: 'hrv',
              value: _currentMeasurements['hrv']!,
              timestamp: DateTime.now(),
            ),
          );
        }
        break;
      case 'spo2':
        if (_currentMeasurements['spo2'] != null) {
          await healthProvider.addHealthMetric(
            HealthMetric(
              id: 0,
              type: 'spo2',
              value: _currentMeasurements['spo2']!,
              timestamp: DateTime.now(),
            ),
          );
        }
        break;
    }
  }

  @override
  void dispose() {
    _measurementTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: _getColor(),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: _isInitialized
                  ? Stack(
                      children: [
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraService
                                  .controller!
                                  .value
                                  .previewSize!
                                  .height,
                              height: _cameraService
                                  .controller!
                                  .value
                                  .previewSize!
                                  .width,
                              child: CameraPreview(_cameraService.controller!),
                            ),
                          ),
                        ),
                        _buildOverlay(),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),

          // Status and Controls
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Countdown timer
                    if (_isMeasuring) _buildCountdownTimer(),

                    const SizedBox(height: 16),

                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Current measurement display
                    if (_currentMeasurements.isNotEmpty)
                      _buildMeasurementDisplay(),

                    const SizedBox(height: 16),

                    // Control buttons
                    if (!_isMeasuring)
                      ElevatedButton.icon(
                        onPressed: _isInitialized ? _startMeasurement : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Measurement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _isMeasuring ? Colors.red : Colors.white,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      margin: const EdgeInsets.all(50),
      child: const Center(
        child: Icon(Icons.fingerprint, color: Colors.white, size: 50),
      ),
    );
  }

  Widget _buildCountdownTimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Text(
            'Time Remaining',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_remainingSeconds',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          Text(
            'seconds',
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Current Reading',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          _buildMeasurementValue(),
        ],
      ),
    );
  }

  Widget _buildMeasurementValue() {
    switch (widget.type) {
      case 'heart_rate':
        final value = _currentMeasurements['heart_rate'];
        return Text(
          value != null ? '${value.round()} BPM' : '-- BPM',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        );
      case 'blood_pressure':
        final systolic = _currentMeasurements['systolic'];
        final diastolic = _currentMeasurements['diastolic'];
        return Text(
          (systolic != null && diastolic != null)
              ? '${systolic.round()}/${diastolic.round()} mmHg'
              : '--/-- mmHg',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        );
      case 'hrv':
        final value = _currentMeasurements['hrv'];
        return Text(
          value != null ? '${value.toStringAsFixed(1)} ms' : '-- ms',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        );
      case 'spo2':
        final value = _currentMeasurements['spo2'];
        return Text(
          value != null ? '${value.round()}%' : '--%',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        );
      default:
        return const Text('--');
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case 'heart_rate':
        return 'Heart Rate Measurement';
      case 'blood_pressure':
        return 'Blood Pressure Measurement';
      case 'hrv':
        return 'HRV Measurement';
      case 'spo2':
        return 'SpO2 Measurement';
      default:
        return 'Health Measurement';
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case 'heart_rate':
        return Colors.red[600]!;
      case 'blood_pressure':
        return Colors.orange[600]!;
      case 'hrv':
        return Colors.green[600]!;
      case 'spo2':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
