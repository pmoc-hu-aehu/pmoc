import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PmocApp());
}

class PmocApp extends StatelessWidget {
  const PmocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMOC HU Londrina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1d4ed8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}