import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    final notices = <(String, String, String, bool)>[
      (
        'Booking confirmed 🎉',
        'Rajesh Kumar accepted your AC service booking for ${state.slot}.',
        '2 min ago',
        true
      ),
      (
        'Provider is on the way',
        'Your technician will arrive shortly. Track your order for live status.',
        '18 min ago',
        true
      ),
      (
        'Payment successful',
        '₹${state.amount + AppState.platformFee} payment received for order #HFU10284.',
        'Today',
        false
      ),
      (
        'New providers nearby',
        '3 top-rated AC professionals are available in your area.',
        'Yesterday',
        false
      ),
    ];

    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text('Notifications',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 14),
            ...notices.map((n) => _Notice(
                  title: n.$1,
                  body: n.$2,
                  time: n.$3,
                  unread: n.$4,
                )),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });
  final String title;
  final String body;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (unread)
            Container(
              width: 3,
              margin: const EdgeInsets.only(right: 11),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.5)),
                const SizedBox(height: 6),
                Text(time,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9AA7B6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
