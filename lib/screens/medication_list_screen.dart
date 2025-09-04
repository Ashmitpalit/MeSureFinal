import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import 'medication_add_screen.dart';
import 'medication_edit_screen.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MedicationAddScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, medicationProvider, child) {
          final medications = medicationProvider.medications;

          if (medications.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return _buildMedicationCard(context, medication);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MedicationAddScreen()),
        ),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No medications added yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first medication to start tracking',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicationAddScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMedicationDetails(context, medication),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medication,
                    color: medication.isActive ? Colors.blue[600] : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${medication.dosage} - ${medication.frequencyDisplay}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!medication.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Reminder times
              if (medication.reminderTimes.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reminders: ${medication.reminderTimeStrings.join(', ')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Notes
              if (medication.notes != null && medication.notes!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        medication.notes!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _showMedicationDetails(context, medication),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _editMedication(context, medication),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteMedication(context, medication),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicationDetails(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medication.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Dosage', medication.dosage),
            _buildDetailRow('Frequency', medication.frequencyDisplay),
            _buildDetailRow(
              'Status',
              medication.isActive ? 'Active' : 'Inactive',
            ),
            if (medication.reminderTimes.isNotEmpty)
              _buildDetailRow(
                'Reminder Times',
                medication.reminderTimeStrings.join(', '),
              ),
            _buildDetailRow(
              'Start Date',
              '${medication.startDate.day}/${medication.startDate.month}/${medication.startDate.year}',
            ),
            if (medication.endDate != null)
              _buildDetailRow(
                'End Date',
                '${medication.endDate!.day}/${medication.endDate!.month}/${medication.endDate!.year}',
              ),
            if (medication.notes != null && medication.notes!.isNotEmpty)
              _buildDetailRow('Notes', medication.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editMedication(context, medication);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editMedication(BuildContext context, Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationEditScreen(medication: medication),
      ),
    );
  }

  void _deleteMedication(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete "${medication.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<MedicationProvider>(
                context,
                listen: false,
              ).deleteMedication(medication.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
