import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'Information We Collect',
      'Account details, service requests, address, device information and transaction data.'
    ),
    (
      'How We Use Data',
      'To match providers, communicate booking updates, process payments and improve services.'
    ),
    (
      'Location Data',
      'Location is used to surface nearby providers and support live order tracking.'
    ),
    (
      'Payments',
      'Payment credentials are handled through secure payment partners; sensitive card data is not stored in the app UI.'
    ),
    (
      'Your Controls',
      'You can manage notifications, saved addresses and account preferences from Settings.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const MiniHeader(title: 'Privacy Policy'),
            const _PolicyCard(
              title: 'Your Privacy Matters',
              body:
                  'HelpFourU uses your account, location and booking information to connect you with service professionals, process payments and provide order tracking.',
            ),
            ..._sections.map(
              (s) => _PolicyCard(title: s.$1, body: s.$2),
            ),
            const SizedBox(height: 6),
            SecondaryButton(
              label: 'Request My Data / Delete Account',
              onTap: () =>
                  showAppToast(context, 'Privacy request submitted'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.muted, height: 1.6)),
        ],
      ),
    );
  }
}
