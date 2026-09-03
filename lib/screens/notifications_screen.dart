import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);

    final notices = <_NoticeData>[
      _NoticeData(
        icon: FontAwesomeIcons.circleCheck,
        accent: AppColors.success,
        title: l10n.noticeBookingConfirmedTitle,
        body: l10n.noticeBookingConfirmedBody(state.slot),
        time: l10n.minAgo,
        unread: true,
      ),
      _NoticeData(
        icon: FontAwesomeIcons.truck,
        accent: AppColors.blue,
        title: l10n.noticeProviderOnWayTitle,
        body: l10n.noticeProviderOnWayBody,
        time: l10n.minAgo18,
        unread: true,
      ),
      _NoticeData(
        icon: FontAwesomeIcons.indianRupeeSign,
        accent: AppColors.greenDark,
        title: l10n.noticePaymentSuccessTitle,
        body: l10n.noticePaymentSuccessBody(state.amount + AppState.platformFee),
        time: l10n.todayLabel,
        unread: false,
      ),
      _NoticeData(
        icon: FontAwesomeIcons.userGroup,
        accent: AppColors.purple,
        title: l10n.noticeNewProvidersTitle,
        body: l10n.noticeNewProvidersBody,
        time: l10n.yesterdayLabel,
        unread: false,
      ),
    ];

    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              l10n.notificationsTitleHeading,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            ...notices.map((n) => _Notice(data: n)),
          ],
        ),
      ),
    );
  }
}

/// One notification row's content, typed so each notice carries its own
/// icon and accent colour.
class _NoticeData {
  const _NoticeData({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });

  final FaIconData icon;
  final Color accent;
  final String title;
  final String body;
  final String time;
  final bool unread;
}

class _Notice extends StatelessWidget {
  const _Notice({required this.data});

  final _NoticeData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent rail is always laid out so read and unread cards
            // share one text baseline; only its colour changes.
            Container(
              width: 3,
              color: data.unread ? data.accent : Colors.transparent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading icon chip, matching the
                    // account/settings list rhythm.
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: data.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: FaIcon(data.icon, size: 14, color: data.accent),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data.body,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9AA7B6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
