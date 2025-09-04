class HealthMetric {
  final int id;
  final String type; // 'heart_rate', 'blood_pressure', 'hrv', 'spo2'
  final double value;
  final String? secondaryValue; // For blood pressure (diastolic)
  final DateTime timestamp;
  final String? notes;

  HealthMetric({
    required this.id,
    required this.type,
    required this.value,
    this.secondaryValue,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'secondary_value': secondaryValue,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      id: map['id'],
      type: map['type'],
      value: map['value'],
      secondaryValue: map['secondary_value'],
      timestamp: DateTime.parse(map['timestamp']),
      notes: map['notes'],
    );
  }

  String get displayValue {
    switch (type) {
      case 'heart_rate':
        return '${value.round()} BPM';
      case 'blood_pressure':
        return '${value.round()}/${double.tryParse(secondaryValue ?? '0')?.round() ?? 0} mmHg';
      case 'hrv':
        return '${value.toStringAsFixed(1)} ms';
      case 'spo2':
        return '${value.round()}%';
      default:
        return value.toString();
    }
  }

  String get unit {
    switch (type) {
      case 'heart_rate':
        return 'BPM';
      case 'blood_pressure':
        return 'mmHg';
      case 'hrv':
        return 'ms';
      case 'spo2':
        return '%';
      default:
        return '';
    }
  }
}
