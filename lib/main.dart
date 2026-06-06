import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Habilita persistência offline do Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const ProviderScope(child: CacauDaNetaApp()));
}

class CacauDaNetaApp extends StatelessWidget {
  const CacauDaNetaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cacau da Neta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
