import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  /// (title, subtitle, kind). 0 = done, 1 = current, 2 = pending. Subtitles
  /// that are fixed clock times ("10:02 AM") stay as-is; "Pending" and the
  /// ETA range are localized in [build] via [_stepSubtitle].
  static const _steps = <(String, String, int)>[
    ('Booking confirmed', '10:02 AM', 0),
    ('Provider accepted', '10:05 AM', 0),
    ('Provider on the way', 'ETA 12–18 min', 1),
    ('Service started', 'Pending', 2),
    ('Job completed', 'Pending', 2),
  ];

  static String _stepTitle(AppLocalizations l10n, String key) => switch (key) {
    'Booking confirmed' => l10n.stepBookingConfirmed,
    'Provider accepted' => l10n.stepProviderAccepted,
    'Provider on the way' => l10n.stepProviderOnTheWay,
    'Service started' => l10n.stepServiceStarted,
    'Job completed' => l10n.stepJobCompleted,
    _ => key,
  };

  static String _stepSubtitle(AppLocalizations l10n, String key) => switch (key) {
    'ETA 12–18 min' => l10n.etaMinutesRange,
    'Pending' => l10n.pendingLabel,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.trackOrderTitle),

            AppCard(
              radius: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.orderNumberLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.subWithProviderName(localizedServiceName(context, state.sub)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pill(label: l10n.onTheWayBadge, fontSize: 9.5),
                ],
              ),
            ),

            // Stylised map placeholder matching the prototype's CSS art.
            const _MapArt(),
            const SizedBox(height: 10),

            AppCard(
              radius: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.providerOnTheWay,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.etaDistance,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showAppToast(context, l10n.callingProviderToast),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.phone,
                            size: 12,
                            color: AppColors.greenDark,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.call,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            ...List.generate(_steps.length, (i) {
              final (title, sub, kind) = _steps[i];
              return _TimelineStep(
                title: _stepTitle(l10n, title),
                subtitle: _stepSubtitle(l10n, sub),
                kind: kind,
                index: i,
                isLast: i == _steps.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MapArt extends StatelessWidget {
  const _MapArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFFDFE9E4), Color(0xFFEDF3F7)],
        ),
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(17),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            // Two crossing "roads".
            Positioned(
              left: -40,
              right: -40,
              top: 90,
              child: Transform.rotate(
                angle: -0.384, // -22deg
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD6E0E8)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              right: -40,
              top: 120,
              child: Transform.rotate(
                angle: 0.436, // 25deg
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD6E0E8)),
                  ),
                ),
              ),
            ),
            // Location pin.
            const Positioned(
              left: 0,
              right: 0,
              top: 62,
              child: Align(
                alignment: Alignment(0.32, 0),
                child: FaIcon(
                  FontAwesomeIcons.locationDot,
                  size: 34,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.index,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final int kind; // 0 done, 1 current, 2 pending
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final active = kind != 2;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.mint : const Color(0xFFDCE5EC),
                  shape: BoxShape.circle,
                ),
                child: kind == 0
                    ? const FaIcon(
                        FontAwesomeIcons.check,
                        size: 11,
                        color: AppColors.greenDark,
                      )
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: active ? AppColors.greenDark : AppColors.muted,
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: active
                        ? AppColors.mintBorder
                        : const Color(0xFFDCE5EC),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
