import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/prediction_api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CharitosApp());
}

class CharitosApp extends StatelessWidget {
  const CharitosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final predictionApiService = PredictionApiService();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pastelería Charito’s',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8D4E2F)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return DashboardScreen(
              authService: authService,
              firestoreService: firestoreService,
              predictionApiService: predictionApiService,
            );
          }

          return LoginScreen(authService: authService);
        },
      ),
    );
  }
}
