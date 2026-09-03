import 'package:flutter/material.dart';
import '../core/services/token_storage.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'shell.dart';

/// Decides where the app opens:
/// - a saved login (from a prior successful `auth/verify-otp` + profile
///   save) found in local storage → straight into [AppShell];
/// - no saved login, but onboarding has been shown before → [LoginScreen];
/// - otherwise (first ever launch) → [OnboardingScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final isLoggedIn = await TokenStorage.hasAuthData();
    final hasSeenOnboarding = await TokenStorage.hasSeenOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn
            ? const AppShell()
            : hasSeenOnboarding
            ? const LoginScreen()
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/logo.png',
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
