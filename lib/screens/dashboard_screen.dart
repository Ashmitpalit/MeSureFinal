import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../providers/medication_provider.dart';
import 'health_measurement_screen.dart';
import 'medication_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Monitor'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Metrics Section
            _buildSectionTitle('Health Metrics'),
            const SizedBox(height: 16),
            _buildHealthMetricsGrid(context),
            const SizedBox(height: 32),

            // Recent Measurements
            _buildSectionTitle('Recent Measurements'),
            const SizedBox(height: 16),
            _buildRecentMeasurements(context),
            const SizedBox(height: 32),

            // Medications Section
            _buildSectionTitle('Medications'),
            const SizedBox(height: 16),
            _buildMedicationsSection(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMeasurementOptions(context),
        icon: const Icon(Icons.favorite),
        label: const Text('Measure'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildHealthMetricsGrid(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, healthProvider, child) {
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              'Heart Rate',
              Icons.favorite,
              Colors.red,
              healthProvider.latestHeartRate?.displayValue ?? '--',
              () => _navigateToMeasurement(context, 'heart_rate'),
            ),
            _buildMetricCard(
              'Blood Pressure',
              Icons.monitor_heart,
              Colors.orange,
              healthProvider.latestBloodPressure?.displayValue ?? '--',
              () => _navigateToMeasurement(context, 'blood_pressure'),
            ),
            _buildMetricCard(
              'HRV',
              Icons.timeline,
              Colors.green,
              healthProvider.latestHRV?.displayValue ?? '--',
              () => _navigateToMeasurement(context, 'hrv'),
            ),
            _buildMetricCard(
              'SpO2',
              Icons.air,
              Colors.blue,
              healthProvider.latestSpO2?.displayValue ?? '--',
              () => _navigateToMeasurement(context, 'spo2'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    IconData icon,
    Color color,
    String value,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMeasurements(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, healthProvider, child) {
        final recentMeasurements = healthProvider.recentMeasurements;

        if (recentMeasurements.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No measurements yet.\nTap "Measure" to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentMeasurements.length,
            itemBuilder: (context, index) {
              final measurement = recentMeasurements[index];
              return ListTile(
                leading: Icon(
                  _getMetricIcon(measurement.type),
                  color: _getMetricColor(measurement.type),
                ),
                title: Text(_getMetricTitle(measurement.type)),
                subtitle: Text(
                  _formatDateTime(measurement.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  measurement.displayValue,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getMetricColor(measurement.type),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMedicationsSection(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, medicationProvider, child) {
        final medications = medicationProvider.activeMedications;

        return Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Active Medications'),
                trailing: Text('${medications.length}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicationListScreen(),
                  ),
                ),
              ),
              if (medications.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No medications added yet.\nTap to add your first medication.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...medications
                    .take(3)
                    .map(
                      (medication) => ListTile(
                        leading: const Icon(Icons.medication),
                        title: Text(medication.name),
                        subtitle: Text(
                          '${medication.dosage} - ${medication.frequencyDisplay}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MedicationListScreen(),
                          ),
                        ),
                      ),
                    ),
              if (medications.length > 3)
                ListTile(
                  title: Text('+${medications.length - 3} more'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MedicationListScreen(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showMeasurementOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Measurement Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMeasurementOption(
              context,
              'Heart Rate',
              Icons.favorite,
              Colors.red,
              'heart_rate',
            ),
            _buildMeasurementOption(
              context,
              'Blood Pressure',
              Icons.monitor_heart,
              Colors.orange,
              'blood_pressure',
            ),
            _buildMeasurementOption(
              context,
              'HRV',
              Icons.timeline,
              Colors.green,
              'hrv',
            ),
            _buildMeasurementOption(
              context,
              'SpO2',
              Icons.air,
              Colors.blue,
              'spo2',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String type,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        _navigateToMeasurement(context, type);
      },
    );
  }

  void _navigateToMeasurement(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthMeasurementScreen(type: type),
      ),
    );
  }

  IconData _getMetricIcon(String type) {
    switch (type) {
      case 'heart_rate':
        return Icons.favorite;
      case 'blood_pressure':
        return Icons.monitor_heart;
      case 'hrv':
        return Icons.timeline;
      case 'spo2':
        return Icons.air;
      default:
        return Icons.health_and_safety;
    }
  }

  Color _getMetricColor(String type) {
    switch (type) {
      case 'heart_rate':
        return Colors.red;
      case 'blood_pressure':
        return Colors.orange;
      case 'hrv':
        return Colors.green;
      case 'spo2':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getMetricTitle(String type) {
    switch (type) {
      case 'heart_rate':
        return 'Heart Rate';
      case 'blood_pressure':
        return 'Blood Pressure';
      case 'hrv':
        return 'Heart Rate Variability';
      case 'spo2':
        return 'Blood Oxygen';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
