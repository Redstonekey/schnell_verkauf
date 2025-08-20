import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';
import 'services/camera_service.dart';
import 'services/api_key_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await Future.wait([
    CameraService.initialize(),
    ApiKeyManager.initialize(),
  ]);
  
  final completed = await OnboardingService.isCompleted();
  runApp(SchnellVerkaufApp(onboardingCompleted: completed));
}

class SchnellVerkaufApp extends StatelessWidget {
  final bool onboardingCompleted;
  const SchnellVerkaufApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  title: 'Schnell Verkaufen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
  home: onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
