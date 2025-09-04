import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';

class MedicationAddScreen extends StatefulWidget {
  const MedicationAddScreen({super.key});

  @override
  State<MedicationAddScreen> createState() => _MedicationAddScreenState();
}

class _MedicationAddScreenState extends State<MedicationAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  String _frequency = 'daily';
  List<int> _reminderTimes = [9]; // Default to 9 AM
  DateTime? _endDate;
  bool _hasEndDate = false;

  final List<String> _frequencyOptions = [
    'daily',
    'twice_daily',
    'three_times_daily',
    'as_needed',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Medication Name
            _buildTextField(
              controller: _nameController,
              label: 'Medication Name',
              hint: 'e.g., Aspirin, Metformin',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Dosage
            _buildTextField(
              controller: _dosageController,
              label: 'Dosage',
              hint: 'e.g., 100mg, 1 tablet',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Frequency
            _buildDropdown(
              label: 'Frequency',
              value: _frequency,
              items: _frequencyOptions.map((freq) {
                return DropdownMenuItem(
                  value: freq,
                  child: Text(_getFrequencyDisplay(freq)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _frequency = value!;
                  _updateReminderTimes();
                });
              },
            ),

            const SizedBox(height: 16),

            // Reminder Times
            _buildReminderTimesSection(),

            const SizedBox(height: 16),

            // End Date
            _buildEndDateSection(),

            const SizedBox(height: 16),

            // Notes
            _buildTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hint: 'Additional information about this medication',
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _saveMedication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Save Medication',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Times',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reminderTimes.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return Chip(
              label: Text(_formatTime(time)),
              onDeleted: _reminderTimes.length > 1
                  ? () => _removeReminderTime(index)
                  : null,
              deleteIcon: const Icon(Icons.close, size: 18),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addReminderTime,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Time'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildEndDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _hasEndDate,
              onChanged: (value) {
                setState(() {
                  _hasEndDate = value ?? false;
                  if (!_hasEndDate) {
                    _endDate = null;
                  }
                });
              },
            ),
            const Text('Set end date'),
          ],
        ),
        if (_hasEndDate) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectEndDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Select end date',
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _updateReminderTimes() {
    switch (_frequency) {
      case 'daily':
        _reminderTimes = [9]; // 9 AM
        break;
      case 'twice_daily':
        _reminderTimes = [9, 21]; // 9 AM, 9 PM
        break;
      case 'three_times_daily':
        _reminderTimes = [8, 14, 20]; // 8 AM, 2 PM, 8 PM
        break;
      case 'as_needed':
        _reminderTimes = []; // No automatic reminders
        break;
    }
  }

  void _addReminderTime() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      final hour = selectedTime.hour;
      if (!_reminderTimes.contains(hour)) {
        setState(() {
          _reminderTimes.add(hour);
          _reminderTimes.sort();
        });
      }
    }
  }

  void _removeReminderTime(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
  }

  Future<void> _selectEndDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _endDate = selectedDate;
      });
    }
  }

  String _formatTime(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period';
  }

  String _getFrequencyDisplay(String frequency) {
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

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final medication = Medication(
      id: 0, // Will be auto-generated
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      reminderTimes: _reminderTimes,
      startDate: DateTime.now(),
      endDate: _hasEndDate ? _endDate : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await Provider.of<MedicationProvider>(
        context,
        listen: false,
      ).addMedication(medication);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding medication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
