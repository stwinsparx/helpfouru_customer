import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  List<(String, String)> _sections(AppLocalizations l10n) => [
    (l10n.privacySection1Title, l10n.privacySection1Body),
    (l10n.privacySection2Title, l10n.privacySection2Body),
    (l10n.privacySection3Title, l10n.privacySection3Body),
    (l10n.privacySection4Title, l10n.privacySection4Body),
    (l10n.privacySection5Title, l10n.privacySection5Body),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.privacyPolicyHeader),
            _PolicyCard(
              title: l10n.yourPrivacyMattersTitle,
              body: l10n.yourPrivacyMattersBody,
            ),
            ..._sections(l10n).map((s) => _PolicyCard(title: s.$1, body: s.$2)),
            const SizedBox(height: 6),
            SecondaryButton(
              label: l10n.requestDataDeleteAccount,
              onTap: () => showAppToast(context, l10n.privacyRequestSubmittedToast),
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
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
