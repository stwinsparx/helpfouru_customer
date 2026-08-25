import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Support hub reached from Profile → Help & Support.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _faqs = <(String, String)>[
    (
      'How do I reschedule a booking?',
      'Open the order from My Orders, tap Track Order and choose Reschedule. Free up to 2 hours before the slot.',
    ),
    (
      'When am I charged for a service?',
      'Payment is taken when you place the order. Add-ons agreed on site are billed separately in the final invoice.',
    ),
    (
      'What is your refund policy?',
      'Cancel more than 2 hours before the slot for a full refund. Refunds reach the original payment method in 3-5 working days.',
    ),
    (
      'Are professionals background verified?',
      'Yes. Every provider passes identity and service-experience checks before they can accept jobs on HelpFourU.',
    ),
    (
      'How do I raise a complaint about a job?',
      'Open the completed order and tap Rate Service, or start a chat below and our team will follow up within 24 hours.',
    ),
  ];

  int? _open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const MiniHeader(title: 'Help & Support'),

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
                  const Text(
                    'We’re here to help',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Our support team replies within minutes, 24 hours a day.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xD9FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const SectionHead(title: 'Quick Help'),
            Row(
              children: [
                _QuickHelp(
                  icon: FontAwesomeIcons.receipt,
                  label: 'Booking\nIssue',
                  onTap: () => showAppToast(context, 'Booking help opened'),
                ),
                _QuickHelp(
                  icon: FontAwesomeIcons.creditCard,
                  label: 'Payment\n& Refund',
                  onTap: () => showAppToast(context, 'Payment help opened'),
                ),
                _QuickHelp(
                  icon: FontAwesomeIcons.userGear,
                  label: 'Account\nHelp',
                  onTap: () => showAppToast(context, 'Account help opened'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const SectionHead(title: 'Frequently Asked Questions'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(_faqs.length, (i) {
                  final (q, a) = _faqs[i];
                  final open = _open == i;
                  return Container(
                    decoration: BoxDecoration(
                      border: i == _faqs.length - 1
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

            const SectionHead(title: 'Reach Us'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ContactRow(
                    icon: FontAwesomeIcons.envelope,
                    title: 'Email',
                    value: 'support@helpfouru.com',
                    onTap: () => showAppToast(context, 'Email app opened'),
                  ),
                  _ContactRow(
                    icon: FontAwesomeIcons.phone,
                    title: 'Toll Free',
                    value: '1800 200 4567',
                    onTap: () => showAppToast(context, 'Calling support...'),
                  ),
                  _ContactRow(
                    icon: FontAwesomeIcons.clock,
                    title: 'Support Hours',
                    value: 'Open 24 × 7',
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
