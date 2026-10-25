import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smart_auth/smart_auth.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService();
  final _mobile = TextEditingController();
  String _code = '+91';
  bool _isSubmitting = false;
  late final _termsTap = TapGestureRecognizer()..onTap = _showTerms;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _getPhoneNumberHint);
  }

  @override
  void dispose() {
    _mobile.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  Future<void> _getPhoneNumberHint() async {
    if (!Platform.isAndroid) return;
    final smartAuth = SmartAuth.instance;
    final res = await smartAuth.requestPhoneNumberHint();

    if (res.hasData && mounted) {
      String number = res.data ?? '';
      number = number.replaceAll('+91', '');
      number = number.replaceAll(' ', '');
      _mobile.text = number;
    }
  }

  Future<void> _continue() async {
    setState(() => _isSubmitting = true);
    var isSuccess = false;
    var hadException = false;
    String? errorMessage;
    try {
      final response = await _apiService.post(
        '/auth/customer/login',
        data: {'phone': _mobile.text.trim(), 'user_type_id': 2},
      );
      isSuccess = response.data['is_success'] == true;
      if (!isSuccess) {
        errorMessage = response.data['message'] as String?;
      }
    } catch (e) {
      isSuccess = false;
      hadException = true;
      debugPrint('Login API error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!mounted) return;
    if (!isSuccess) {
      final l10n = AppLocalizations.of(context);
      showAppToast(
        context,
        errorMessage ??
            (hadException ? l10n.somethingWentWrongTryAgain : l10n.loginFailed),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OtpScreen(mobile: _mobile.text.trim(), countryCode: _code),
      ),
    );
  }

  void _showTerms() {
    showDialog(context: context, builder: (_) => const _TermsDialog());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.welcomeToApp,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.loginSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 26),
              LabeledField(
                label: l10n.mobileNumberLabel,
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
                        onTap: () {
                          if (_mobile.text.isEmpty) _getPhoneNumberHint();
                        },
                        decoration: appInputDecoration(
                          l10n.enterMobileNumberHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PrimaryButton(
                label: _isSubmitting ? l10n.pleaseWait : l10n.continueWithOtp,
                onTap: _isSubmitting ? null : _continue,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE1E7ED))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        l10n.orDivider,
                        style: const TextStyle(
                          color: Color(0xFFA0ACB9),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE1E7ED))),
                  ],
                ),
              ),
              LabeledField(
                label: l10n.emailOptionalLabel,
                child: TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: appInputDecoration(l10n.emailHint),
                ),
              ),
              SecondaryButton(
                label: l10n.loginWithEmail,
                onTap: _isSubmitting ? null : _continue,
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  children: [
                    TextSpan(text: l10n.agreeToTermsPrefix),
                    TextSpan(
                      text: l10n.termsAndPrivacyPolicy,
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: _termsTap,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsDialog extends StatelessWidget {
  const _TermsDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = <(String, String)>[
      (l10n.termsSection1Title, l10n.termsSection1Body),
      (l10n.termsSection2Title, l10n.termsSection2Body),
      (l10n.termsSection3Title, l10n.termsSection3Body),
      (l10n.termsSection4Title, l10n.termsSection4Body),
      (l10n.termsSection5Title, l10n.termsSection5Body),
    ];
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.termsAndConditionsTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.termsIntro,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final s in sections) ...[
                        Text(
                          s.$1,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.close,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
