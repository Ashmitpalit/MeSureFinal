import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/health_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
      ],
      child: MaterialApp(
        title: 'MeSure',
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
          iconTheme: const IconThemeData(color: Colors.blue, size: 24),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
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
              Text('Initializing MeSure...'),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state
        if (authProvider.user == null) {
          return const LoginScreen();
        }

        // If user exists but email is not verified, show verification screen
        if (authProvider.user != null && !authProvider.user!.emailVerified) {
          return const VerificationScreen();
        }

        // If user is verified but not authenticated (needs to sign in), show login
        if (authProvider.user != null &&
            authProvider.user!.emailVerified &&
            !authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // User is authenticated, show dashboard
        return const DashboardScreen();
      },
    );
  }
}
