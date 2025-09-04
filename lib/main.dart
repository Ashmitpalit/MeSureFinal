import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/health_provider.dart';
import 'providers/medication_provider.dart';
import 'services/notification_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  runApp(const PPGApp());
}

class PPGApp extends StatelessWidget {
  const PPGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
      ],
      child: MaterialApp(
        title: 'PPG Health Monitor',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load initial data
      if (mounted) {
        await context.read<HealthProvider>().loadHealthMetrics();
        await context.read<MedicationProvider>().loadMedications();

        // Reschedule medication reminders
        await context.read<MedicationProvider>().rescheduleAllReminders();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Still show the app even if there's an error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing Health Monitor...'),
            ],
          ),
        ),
      );
    }

    return const DashboardScreen();
  }
}
