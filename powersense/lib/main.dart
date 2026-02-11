import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const PowerSenseApp());
}

class PowerSenseApp extends StatelessWidget {
  const PowerSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0066CC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066CC),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      home: const SplashScreen(), // Começa com splash que verifica autenticação
    );
  }
}
