import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class MedicationProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Medication> _medications = [];

  List<Medication> get medications => _medications;
  List<Medication> get activeMedications =>
      _medications.where((med) => med.isActive).toList();

  Future<void> loadMedications() async {
    try {
      _medications = await _databaseHelper.getMedications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading medications: $e');
    }
  }

  Future<void> addMedication(Medication medication) async {
    try {
      final id = await _databaseHelper.insertMedication(medication);
      final newMedication = Medication(
        id: id,
        name: medication.name,
        dosage: medication.dosage,
        frequency: medication.frequency,
        reminderTimes: medication.reminderTimes,
        startDate: medication.startDate,
        endDate: medication.endDate,
        notes: medication.notes,
        isActive: medication.isActive,
      );

      _medications.add(newMedication);
      _medications.sort((a, b) => a.name.compareTo(b.name));

      // Schedule notifications for active medications
      if (newMedication.isActive) {
        await NotificationService.scheduleMedicationReminder(newMedication);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding medication: $e');
      rethrow;
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      await _databaseHelper.updateMedication(medication);

      // Cancel existing notifications
      await NotificationService.cancelMedicationReminders(medication.id);

      // Update in local list
      final index = _medications.indexWhere((med) => med.id == medication.id);
      if (index != -1) {
        _medications[index] = medication;
        _medications.sort((a, b) => a.name.compareTo(b.name));
      }

      // Schedule new notifications if active
      if (medication.isActive) {
        await NotificationService.scheduleMedicationReminder(medication);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  Future<void> deleteMedication(int id) async {
    try {
      await _databaseHelper.deleteMedication(id);

      // Cancel notifications
      await NotificationService.cancelMedicationReminders(id);

      _medications.removeWhere((med) => med.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting medication: $e');
    }
  }

  Future<void> logMedicationTaken(int medicationId, {String? notes}) async {
    try {
      await _databaseHelper.logMedicationTaken(medicationId, notes: notes);
      // Could add UI feedback here if needed
    } catch (e) {
      debugPrint('Error logging medication taken: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMedicationLogs(
    int medicationId, {
    int? days,
  }) async {
    try {
      return await _databaseHelper.getMedicationLogs(medicationId, days: days);
    } catch (e) {
      debugPrint('Error getting medication logs: $e');
      return [];
    }
  }

  // Get medications that need reminders at a specific time
  List<Medication> getMedicationsForReminder(DateTime time) {
    final hour = time.hour;
    return activeMedications.where((med) {
      return med.reminderTimes.contains(hour);
    }).toList();
  }

  // Get medications that are due for reminders now
  List<Medication> getMedicationsDueNow() {
    final now = DateTime.now();
    return getMedicationsForReminder(now);
  }

  // Get medications by frequency
  List<Medication> getMedicationsByFrequency(String frequency) {
    return activeMedications
        .where((med) => med.frequency == frequency)
        .toList();
  }

  // Get medications that are ending soon (within next 7 days)
  List<Medication> getMedicationsEndingSoon() {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));

    return activeMedications.where((med) {
      if (med.endDate == null) return false;
      return med.endDate!.isAfter(now) && med.endDate!.isBefore(weekFromNow);
    }).toList();
  }

  // Get medication statistics
  Map<String, int> getMedicationStats() {
    final total = _medications.length;
    final active = activeMedications.length;
    final inactive = total - active;

    final byFrequency = <String, int>{};
    for (final med in activeMedications) {
      byFrequency[med.frequency] = (byFrequency[med.frequency] ?? 0) + 1;
    }

    return {
      'total': total,
      'active': active,
      'inactive': inactive,
      ...byFrequency,
    };
  }

  // Reschedule all medication reminders
  Future<void> rescheduleAllReminders() async {
    try {
      // Cancel all existing reminders
      await NotificationService.cancelAllReminders();

      // Schedule reminders for all active medications
      for (final medication in activeMedications) {
        await NotificationService.scheduleMedicationReminder(medication);
      }
    } catch (e) {
      debugPrint('Error rescheduling reminders: $e');
    }
  }
}
