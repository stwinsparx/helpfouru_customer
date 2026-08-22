import 'package:flutter/material.dart';
import 'models/app_state.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HelpFourUApp());
}

class HelpFourUApp extends StatefulWidget {
  const HelpFourUApp({super.key});

  @override
  State<HelpFourUApp> createState() => _HelpFourUAppState();
}

class _HelpFourUAppState extends State<HelpFourUApp> {
  final _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: MaterialApp(
        title: 'HelpFourU',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const OnboardingScreen(),
      ),
    );
  }
}
