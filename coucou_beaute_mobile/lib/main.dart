import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const CoucouBeauteApp());
}

class CoucouBeauteApp extends StatelessWidget {
  const CoucouBeauteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COUCOU BEAUTÉ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OnboardingScreen(),
    );
  }
}
