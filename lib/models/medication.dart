class Medication {
  final int id;
  final String name;
  final String dosage;
  final String
  frequency; // 'daily', 'twice_daily', 'three_times_daily', 'as_needed'
  final List<int> reminderTimes; // List of hours (0-23) for daily reminders
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.reminderTimes,
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'reminder_times': reminderTimes.join(','),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      reminderTimes: (map['reminder_times'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      notes: map['notes'],
      isActive: map['is_active'] == 1,
    );
  }

  String get frequencyDisplay {
    switch (frequency) {
      case 'daily':
        return 'Once Daily';
      case 'twice_daily':
        return 'Twice Daily';
      case 'three_times_daily':
        return 'Three Times Daily';
      case 'as_needed':
        return 'As Needed';
      default:
        return frequency;
    }
  }

  List<String> get reminderTimeStrings {
    return reminderTimes.map((hour) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:00 $period';
    }).toList();
  }
}
