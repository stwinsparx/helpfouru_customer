import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController(text: '9876543210');
  String _code = '+91';

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  void _continue() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const OtpScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Welcome to HelpFourU',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your trusted local service marketplace',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 26),
              LabeledField(
                label: 'MOBILE NUMBER',
                child: Row(
                  children: [
                    Container(
                      width: 82,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFDCE5ED)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _code,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: '+91', child: Text('+91')),
                            DropdownMenuItem(value: '+1', child: Text('+1')),
                          ],
                          onChanged: (v) => setState(() => _code = v ?? '+91'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _mobile,
                        keyboardType: TextInputType.number,
                        decoration: appInputDecoration('Enter mobile number'),
                      ),
                    ),
                  ],
                ),
              ),
              PrimaryButton(label: 'Continue with OTP', onTap: _continue),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFE1E7ED))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Color(0xFFA0ACB9),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFE1E7ED))),
                  ],
                ),
              ),
              LabeledField(
                label: 'EMAIL (OPTIONAL)',
                child: TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: appInputDecoration('you@example.com'),
                ),
              ),
              SecondaryButton(
                label: 'Login / Sign up with Email',
                onTap: _continue,
              ),
              const SizedBox(height: 16),
              const Text(
                'By continuing, you agree to our Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
