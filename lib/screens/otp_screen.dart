import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import '../core/services/api_service.dart';
import '../core/services/device_info_service.dart';
import '../core/services/token_storage.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'save_profile_screen.dart';
import 'shell.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.mobile, required this.countryCode});

  final String mobile;
  final String countryCode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _otpLength = 6;

  /// How long "Resend OTP" stays disabled after the OTP is (re)sent.
  static const _resendCooldown = Duration(minutes: 3);

  final _apiService = ApiService();
  final _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _nodes = List.generate(_otpLength, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isResending = false;

  Timer? _resendTimer;
  Duration _remainingCooldown = _resendCooldown;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _remainingCooldown = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _remainingCooldown - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        setState(() => _remainingCooldown = Duration.zero);
        return;
      }
      setState(() => _remainingCooldown = next);
    });
  }

  String get _resendCooldownLabel {
    final totalSeconds = _remainingCooldown.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resend() async {
    if (_remainingCooldown > Duration.zero || _isResending) return;
    setState(() => _isResending = true);
    var isSuccess = false;
    String? errorMessage;
    try {
      final response = await _apiService.post(
        '/auth/customer/login',
        data: {'phone': widget.mobile, 'user_type_id': 2},
      );
      isSuccess = response.data['is_success'] == true;
      if (!isSuccess) errorMessage = response.data['message'] as String?;
    } catch (e) {
      debugPrint('Resend OTP API error: $e');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (!isSuccess) {
      showAppToast(context, errorMessage ?? l10n.somethingWentWrongTryAgain);
      return;
    }
    _startResendCooldown();
    showAppToast(context, l10n.newOtpSent);
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    setState(() => _isVerifying = true);
    Map<String, dynamic>? authData;
    String? name;
    String? email;
    String? errorMessage;
    try {
      final deviceName = await DeviceInfoService.deviceName();
      final coordinates = await DeviceInfoService.loginCoordinates();
      final response = await _apiService.post(
        '/auth/verify-otp',
        data: {
          'phone': widget.mobile,
          'otp': otp,
          'firebase_token': '',
          'device_name': deviceName ?? '',
          'login_coordinates': coordinates,
          'login_with': 'mobile',
        },
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        authData = response.data['data'] as Map<String, dynamic>?;
        final user = authData?['user'] as Map<String, dynamic>?;
        final rawName = user?['name'] as String?;
        final rawEmail = user?['email'] as String?;
        // The backend auto-generates a placeholder name/email for brand new
        // accounts ("User <phone>" / "<phone>@customer.helpfouru.com") — skip
        // pre-filling those so the profile form starts blank instead.
        name = (rawName != null && !rawName.startsWith('User '))
            ? rawName
            : null;
        email =
            (rawEmail != null && !rawEmail.endsWith('@customer.helpfouru.com'))
            ? rawEmail
            : null;
      } else {
        errorMessage = response.data['message'] as String?;
      }
    } catch (e) {
      debugPrint('Verify OTP API error: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
    if (!mounted) return;
    final token = authData?['token'] as String?;
    if (authData == null || token == null) {
      showAppToast(
        context,
        errorMessage ?? AppLocalizations.of(context).invalidOrExpiredOtp,
      );
      return;
    }
    final resolvedAuthData = authData;
    final user = resolvedAuthData['user'] as Map<String, dynamic>?;
    final isOnboarded = user?['isOnboarded'] as bool? ?? false;
    if (isOnboarded) {
      await TokenStorage.saveToken(token);
      await TokenStorage.saveAuthData(resolvedAuthData);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaveProfileScreen(
          token: token,
          authData: resolvedAuthData,
          initialName: name,
          initialEmail: email,
        ),
      ),
    );
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
                l10n.verifyYourMobile,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.otpSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  border: Border.all(color: AppColors.mintBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.greenDark,
                        ),
                        children: [
                          TextSpan(text: l10n.otpSentTo),
                          TextSpan(
                            text: '${widget.countryCode} ${widget.mobile}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.otpNeverShare,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A6B5C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.wrongNumberPrefix,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.changeMobileNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: List.generate(_otpLength, (i) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == _otpLength - 1 ? 0 : 7,
                      ),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _nodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: appInputDecoration('').copyWith(
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < _otpLength - 1) {
                            _nodes[i + 1].requestFocus();
                          } else if (v.isEmpty && i > 0) {
                            _nodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.didNotReceiveItPrefix,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  GestureDetector(
                    onTap: _remainingCooldown > Duration.zero ? null : _resend,
                    child: Text(
                      _remainingCooldown > Duration.zero
                          ? l10n.resendOtpIn(_resendCooldownLabel)
                          : l10n.resendOtp,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _remainingCooldown > Duration.zero
                            ? AppColors.muted
                            : AppColors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _isVerifying ? l10n.verifying : l10n.verifyAndContinue,
                onTap: _isVerifying ? null : _verify,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TrustItem(
                      icon: FontAwesomeIcons.lock,
                      label: l10n.secureLogin,
                    ),
                    _TrustItem(
                      icon: FontAwesomeIcons.circleCheck,
                      label: l10n.verifiedAccount,
                    ),
                    _TrustItem(
                      icon: FontAwesomeIcons.headset,
                      label: l10n.support,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});
  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FaIcon(icon, size: 15, color: AppColors.greenDark),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
        ),
      ],
    );
  }
}
