import 'package:cached_network_image/cached_network_image.dart';
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
    this.distance,
    this.jobs,
    this.profileImage,
    this.isVerified = true,
    this.availabilityLabel,
    this.isAvailableNow = false,
    this.onViewProfile,
    this.onBook,
  });

  final String name;
  final String role;
  final String rating;
  final String price;

  /// "Available now" / "Next: Tomorrow 10 AM" line, when known — shown as a
  /// small dot + label under the role line. `null` omits it entirely (e.g.
  /// the backend hasn't started sending `next_available_at` yet).
  final String? availabilityLabel;

  /// Colors [availabilityLabel] green (vs. the muted default) when the
  /// provider has an opening within the instant window right now.
  final bool isAvailableNow;

  /// Distance to the provider (e.g. "2.1 km"), when known. `null` omits the
  /// "· X away" segment entirely rather than showing a dangling separator.
  final String? distance;

  /// Jobs-done label; defaults to the localized "128 jobs" when omitted.
  final String? jobs;

  /// Provider photo URL. `null` (or a failed load) falls back to an
  /// initials avatar.
  final String? profileImage;

  /// Whether to show the verified checkmark badge next to the name.
  final bool isVerified;
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
                clipBehavior: Clip.antiAlias,
                child: profileImage != null && profileImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profileImage!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Text(
                          _initials,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.blueDark,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : Text(
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
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const FaIcon(
                            FontAwesomeIcons.circleCheck,
                            size: 13,
                            color: AppColors.greenDark,
                          ),
                        ],
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
                      distance != null ? '$role · $distance away' : role,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    if (availabilityLabel != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAvailableNow
                                  ? AppColors.green
                                  : AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            availabilityLabel!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isAvailableNow
                                  ? AppColors.greenDark
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                child: _CardButton(
                  label: l10n.viewProfile,
                  onTap: onViewProfile,
                ),
              ),
              const SizedBox(width: 8),
              _CartButton(onTap: onBook, tooltip: l10n.addToCart),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact square cart-icon button, replacing the old "Book Now" text
/// button — tapping it opens Review & Schedule for this card's service.
class _CartButton extends StatelessWidget {
  const _CartButton({this.onTap, required this.tooltip});
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFE6F7EF),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.mintBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const FaIcon(
              FontAwesomeIcons.cartPlus,
              size: 15,
              color: AppColors.greenDark,
            ),
          ),
        ),
      ),
    );
  }
}
