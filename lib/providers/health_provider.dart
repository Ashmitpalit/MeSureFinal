import 'package:flutter/foundation.dart';
import '../models/health_metric.dart';
import '../services/database_helper.dart';

class HealthProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<HealthMetric> _healthMetrics = [];
  HealthMetric? _latestHeartRate;
  HealthMetric? _latestBloodPressure;
  HealthMetric? _latestHRV;
  HealthMetric? _latestSpO2;

  List<HealthMetric> get healthMetrics => _healthMetrics;
  List<HealthMetric> get recentMeasurements => _healthMetrics.take(10).toList();
  HealthMetric? get latestHeartRate => _latestHeartRate;
  HealthMetric? get latestBloodPressure => _latestBloodPressure;
  HealthMetric? get latestHRV => _latestHRV;
  HealthMetric? get latestSpO2 => _latestSpO2;

  Future<void> loadHealthMetrics() async {
    try {
      _healthMetrics = await _databaseHelper.getHealthMetrics();
      _updateLatestMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading health metrics: $e');
    }
  }

  Future<void> addHealthMetric(HealthMetric metric) async {
    try {
      final id = await _databaseHelper.insertHealthMetric(metric);
      final newMetric = HealthMetric(
        id: id,
        type: metric.type,
        value: metric.value,
        secondaryValue: metric.secondaryValue,
        timestamp: metric.timestamp,
        notes: metric.notes,
      );

      _healthMetrics.insert(0, newMetric);
      _updateLatestMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding health metric: $e');
      rethrow;
    }
  }

  Future<void> deleteHealthMetric(int id) async {
    try {
      await _databaseHelper.deleteHealthMetric(id);
      _healthMetrics.removeWhere((metric) => metric.id == id);
      _updateLatestMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting health metric: $e');
    }
  }

  Future<List<HealthMetric>> getHealthMetricsByType(String type) async {
    try {
      return await _databaseHelper.getHealthMetrics(type: type);
    } catch (e) {
      debugPrint('Error getting health metrics by type: $e');
      return [];
    }
  }

  Future<HealthMetric?> getLatestHealthMetric(String type) async {
    try {
      return await _databaseHelper.getLatestHealthMetric(type);
    } catch (e) {
      debugPrint('Error getting latest health metric: $e');
      return null;
    }
  }

  void _updateLatestMetrics() {
    _latestHeartRate = _getLatestMetric('heart_rate');
    _latestBloodPressure = _getLatestMetric('blood_pressure');
    _latestHRV = _getLatestMetric('hrv');
    _latestSpO2 = _getLatestMetric('spo2');
  }

  HealthMetric? _getLatestMetric(String type) {
    try {
      return _healthMetrics.where((metric) => metric.type == type).isNotEmpty
          ? _healthMetrics.where((metric) => metric.type == type).first
          : null;
    } catch (e) {
      return null;
    }
  }

  // Get health metrics for a specific date range
  List<HealthMetric> getHealthMetricsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _healthMetrics.where((metric) {
      return metric.timestamp.isAfter(startDate) &&
          metric.timestamp.isBefore(endDate);
    }).toList();
  }

  // Get health metrics for the last N days
  List<HealthMetric> getHealthMetricsForLastDays(int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getHealthMetricsForDateRange(startDate, endDate);
  }

  // Get average value for a specific metric type over a date range
  double? getAverageValue(String type, DateTime startDate, DateTime endDate) {
    final metrics = getHealthMetricsForDateRange(
      startDate,
      endDate,
    ).where((metric) => metric.type == type).toList();

    if (metrics.isEmpty) return null;

    final sum = metrics.map((metric) => metric.value).reduce((a, b) => a + b);
    return sum / metrics.length;
  }

  // Get trend for a specific metric type (positive, negative, or stable)
  String getTrend(String type, {int days = 7}) {
    final recentMetrics = getHealthMetricsForLastDays(
      days,
    ).where((metric) => metric.type == type).toList();

    if (recentMetrics.length < 2) return 'stable';

    final firstValue = recentMetrics.last.value;
    final lastValue = recentMetrics.first.value;
    final difference = lastValue - firstValue;
    final percentageChange = (difference / firstValue) * 100;

    if (percentageChange > 5) return 'increasing';
    if (percentageChange < -5) return 'decreasing';
    return 'stable';
  }
}
