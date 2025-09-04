import 'dart:math';
import 'dart:typed_data';

class PPGAnalyzer {
  static const int sampleRate = 30; // FPS
  static const int analysisDuration = 15; // seconds
  static const int minSamples = sampleRate * analysisDuration;

  List<double> _redValues = [];
  List<double> _greenValues = [];
  List<double> _blueValues = [];
  List<double> _timestamps = [];

  void addFrame(Uint8List imageData, int width, int height) {
    // For simulation, generate realistic PPG-like data
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final timeSeconds = now / 1000.0;

    // Simulate heart rate around 70 BPM with some variation
    final heartRateHz = 70.0 / 60.0; // Convert BPM to Hz
    final heartSignal = 20 * sin(2 * pi * heartRateHz * timeSeconds);

    // Add some noise and variation
    final noise = sin(timeSeconds * 0.1) * 5;

    // Simulate different channels with slight variations
    final redValue = (100 + heartSignal + noise).toDouble();
    final greenValue = (80 + heartSignal * 0.8 + noise * 0.7).toDouble();
    final blueValue = (60 + heartSignal * 0.6 + noise * 0.5).toDouble();

    _redValues.add(redValue);
    _greenValues.add(greenValue);
    _blueValues.add(blueValue);
    _timestamps.add(now);
  }

  void clearData() {
    _redValues.clear();
    _greenValues.clear();
    _blueValues.clear();
    _timestamps.clear();
  }

  bool hasEnoughData() {
    return _redValues.length >= minSamples;
  }

  // Heart Rate calculation using green channel (most sensitive to blood volume changes)
  double? calculateHeartRate() {
    if (!hasEnoughData()) return null;

    final greenSignal = _greenValues;
    final timestamps = _timestamps;

    // Apply bandpass filter (0.5-4 Hz for heart rate)
    final filteredSignal = _bandpassFilter(greenSignal, 0.5, 4.0, sampleRate);

    // Find peaks in the filtered signal
    final peaks = _findPeaks(filteredSignal);

    if (peaks.length < 2) return null;

    // Calculate time intervals between peaks
    final intervals = <double>[];
    for (int i = 1; i < peaks.length; i++) {
      final timeDiff =
          (timestamps[peaks[i]] - timestamps[peaks[i - 1]]) /
          1000.0; // Convert to seconds
      if (timeDiff > 0.3 && timeDiff < 2.0) {
        // Valid heart rate range
        intervals.add(timeDiff);
      }
    }

    if (intervals.isEmpty) return null;

    // Calculate average interval and convert to BPM
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    return 60.0 / avgInterval;
  }

  // Blood Pressure estimation (simplified algorithm)
  Map<String, double>? calculateBloodPressure() {
    if (!hasEnoughData()) return null;

    final heartRate = calculateHeartRate();
    if (heartRate == null) return null;

    // Simplified estimation based on heart rate and signal characteristics
    final greenSignal = _greenValues;
    final signalVariability = _calculateVariability(greenSignal);

    // These are rough estimates - real BP measurement requires calibration
    final systolic = 80 + (heartRate - 60) * 0.5 + signalVariability * 10;
    final diastolic = 50 + (heartRate - 60) * 0.3 + signalVariability * 5;

    return {
      'systolic': systolic.clamp(80.0, 200.0),
      'diastolic': diastolic.clamp(50.0, 120.0),
    };
  }

  // Heart Rate Variability calculation
  double? calculateHRV() {
    if (!hasEnoughData()) return null;

    final greenSignal = _greenValues;
    final timestamps = _timestamps;

    // Apply bandpass filter
    final filteredSignal = _bandpassFilter(greenSignal, 0.5, 4.0, sampleRate);

    // Find peaks
    final peaks = _findPeaks(filteredSignal);

    if (peaks.length < 3) return null;

    // Calculate RR intervals
    final rrIntervals = <double>[];
    for (int i = 1; i < peaks.length; i++) {
      final timeDiff =
          (timestamps[peaks[i]] - timestamps[peaks[i - 1]]) / 1000.0;
      if (timeDiff > 0.3 && timeDiff < 2.0) {
        rrIntervals.add(timeDiff * 1000); // Convert to milliseconds
      }
    }

    if (rrIntervals.length < 2) return null;

    // Calculate RMSSD (Root Mean Square of Successive Differences)
    double sumSquaredDiffs = 0;
    for (int i = 1; i < rrIntervals.length; i++) {
      final diff = rrIntervals[i] - rrIntervals[i - 1];
      sumSquaredDiffs += diff * diff;
    }

    return sqrt(sumSquaredDiffs / (rrIntervals.length - 1));
  }

  // SpO2 calculation using red and infrared channels
  double? calculateSpO2() {
    if (!hasEnoughData()) return null;

    final redSignal = _redValues;
    final greenSignal = _greenValues;

    // Calculate AC/DC ratios
    final redAC = _calculateACComponent(redSignal);
    final redDC = _calculateDCComponent(redSignal);
    final greenAC = _calculateACComponent(greenSignal);
    final greenDC = _calculateDCComponent(greenSignal);

    if (redDC == 0 || greenDC == 0) return null;

    final redRatio = redAC / redDC;
    final greenRatio = greenAC / greenDC;

    // Simplified SpO2 calculation (requires calibration for accuracy)
    final ratio = redRatio / greenRatio;
    final spo2 = 110 - 25 * ratio;

    return spo2.clamp(70.0, 100.0);
  }

  // Helper methods
  List<double> _bandpassFilter(
    List<double> signal,
    double lowFreq,
    double highFreq,
    int sampleRate,
  ) {
    // Simple bandpass filter implementation
    final filtered = <double>[];

    for (int i = 0; i < signal.length; i++) {
      if (i == 0) {
        filtered.add(signal[i]);
      } else {
        final prev = filtered[i - 1];
        final current = signal[i];
        final filteredValue = prev + (current - prev) * 0.1; // Simple low-pass
        filtered.add(filteredValue);
      }
    }

    return filtered;
  }

  List<int> _findPeaks(List<double> signal) {
    final peaks = <int>[];
    final threshold = _calculateThreshold(signal);

    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i - 1] &&
          signal[i] > signal[i + 1] &&
          signal[i] > threshold) {
        peaks.add(i);
      }
    }

    return peaks;
  }

  double _calculateThreshold(List<double> signal) {
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final variance =
        signal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
        signal.length;
    return mean + sqrt(variance) * 0.5;
  }

  double _calculateVariability(List<double> signal) {
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final variance =
        signal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
        signal.length;
    return sqrt(variance);
  }

  double _calculateACComponent(List<double> signal) {
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final acSignal = signal.map((x) => x - mean).toList();
    return _calculateVariability(acSignal);
  }

  double _calculateDCComponent(List<double> signal) {
    return signal.reduce((a, b) => a + b) / signal.length;
  }
}
