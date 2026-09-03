import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Support hub reached from Profile → Help & Support.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  List<(String, String)> _faqs(AppLocalizations l10n) => [
    (l10n.faqRescheduleQuestion, l10n.faqRescheduleAnswer),
    (l10n.faqChargedQuestion, l10n.faqChargedAnswer),
    (l10n.faqRefundQuestion, l10n.faqRefundAnswer),
    (l10n.faqVerifiedQuestion, l10n.faqVerifiedAnswer),
    (l10n.faqComplaintQuestion, l10n.faqComplaintAnswer),
  ];

  int? _open;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final faqs = _faqs(l10n);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            MiniHeader(title: l10n.helpSupportTitle),

            // Contact banner.
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                gradient: AppGradients.banner,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.hereToHelp,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.supportRepliesWithinMinutes,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xD9FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SectionHead(title: l10n.quickHelp),
            Row(
              children: [
                _QuickHelp(
                  icon: FontAwesomeIcons.receipt,
                  label: l10n.bookingIssue,
                  onTap: () => showAppToast(context, l10n.bookingHelpOpenedToast),
                ),
                _QuickHelp(
                  icon: FontAwesomeIcons.creditCard,
                  label: l10n.paymentAndRefund,
                  onTap: () => showAppToast(context, l10n.paymentHelpOpenedToast),
                ),
                _QuickHelp(
                  icon: FontAwesomeIcons.userGear,
                  label: l10n.accountHelp,
                  onTap: () => showAppToast(context, l10n.accountHelpOpenedToast),
                ),
              ],
            ),
            const SizedBox(height: 18),

            SectionHead(title: l10n.faqTitle),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(faqs.length, (i) {
                  final (q, a) = faqs[i];
                  final open = _open == i;
                  return Container(
                    decoration: BoxDecoration(
                      border: i == faqs.length - 1
                          ? null
                          : const Border(
                              bottom: BorderSide(color: Color(0xFFEDF1F4)),
                            ),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _open = open ? null : i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    q,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FaIcon(
                                  open
                                      ? FontAwesomeIcons.chevronUp
                                      : FontAwesomeIcons.chevronDown,
                                  size: 11,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox(
                            width: double.infinity,
                            height: 0,
                          ),
                          secondChild: Padding(
                            padding: const EdgeInsets.fromLTRB(13, 0, 34, 14),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                a,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),
                          crossFadeState: open
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),

            SectionHead(title: l10n.reachUs),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ContactRow(
                    icon: FontAwesomeIcons.envelope,
                    title: l10n.emailLabelShort,
                    value: 'support@helpfouru.com',
                    onTap: () => showAppToast(context, l10n.emailAppOpenedToast),
                  ),
                  _ContactRow(
                    icon: FontAwesomeIcons.phone,
                    title: l10n.tollFreeLabel,
                    value: '1800 200 4567',
                    onTap: () => showAppToast(context, l10n.callingSupportToast),
                  ),
                  _ContactRow(
                    icon: FontAwesomeIcons.clock,
                    title: l10n.supportHoursLabel,
                    value: l10n.open24x7,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickHelp extends StatelessWidget {
  const _QuickHelp({required this.icon, required this.label, this.onTap});

  final FaIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.5),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: FaIcon(icon, size: 14, color: AppColors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF53667C),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.isLast = false,
  });

  final FaIconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFEDF1F4))),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: FaIcon(icon, size: 12, color: AppColors.greenDark),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 11,
                color: Color(0xFFA4B0BD),
              ),
          ],
        ),
      ),
    );
  }
}
