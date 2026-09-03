import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Reusable listing card — the prototype's `providerCard()`.
class ProviderCard extends StatelessWidget {
  const ProviderCard({
    super.key,
    required this.name,
    required this.role,
    required this.rating,
    required this.price,
    required this.distance,
    this.jobs,
    this.onViewProfile,
    this.onBook,
  });

  final String name;
  final String role;
  final String rating;
  final String price;
  final String distance;

  /// Jobs-done label; defaults to the localized "128 jobs" when omitted.
  final String? jobs;
  final VoidCallback? onViewProfile;
  final VoidCallback? onBook;

  String get _initials =>
      name.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).join();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final jobsLabel = jobs ?? l10n.jobsCount(128);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.providerAvatar,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.blueDark,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const FaIcon(
                          FontAwesomeIcons.circleCheck,
                          size: 13,
                          color: AppColors.greenDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '★ $rating · $jobsLabel',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.star,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$role · $distance away',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _CardButton(label: l10n.viewProfile, onTap: onViewProfile),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardButton(
                  label: l10n.bookNow,
                  onTap: onBook,
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, this.onTap, this.filled = false});
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFFE6F7EF) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: filled ? AppColors.mintBorder : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: filled ? AppColors.greenDark : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
