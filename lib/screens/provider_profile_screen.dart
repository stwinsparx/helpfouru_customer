import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';

/// Fetches and renders `GET /customer/providers/:providerId`.
class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key, required this.providerId});

  final int providerId;

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  ProviderProfileResult? _result;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiService.get(
        '/customer/providers/${widget.providerId}',
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        setState(
          () => _result = ProviderProfileResult.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
    } catch (e) {
      debugPrint('Provider profile API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _initials {
    final name = _result?.provider.name ?? '';
    return name.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).join();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.screenBg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: MiniHeader(title: l10n.providerProfileTitle),
              ),
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.screenBg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              MiniHeader(title: l10n.providerProfileTitle),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    l10n.providerProfileUnavailable,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final provider = result.provider;
    final ratingText = provider.totalReviews > 0
        ? '${provider.rating} ★'
        : l10n.noRatingsYet;
    final experienceText = provider.yearsOfExperience != null
        ? l10n.yearsExperienceValue(provider.yearsOfExperience!)
        : l10n.experienceNotAvailable;
    final aboutText = (provider.about != null && provider.about!.isNotEmpty)
        ? provider.about!
        : l10n.noProviderBioYet;

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.providerProfileTitle),

            // Gradient cover with the overlapping avatar tile.
            SizedBox(
              height: 130,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  Positioned(
                    left: 17,
                    top: 62,
                    child: Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          provider.profileImage != null &&
                              provider.profileImage!.isNotEmpty
                          ? Image.network(
                              provider.profileImage!,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    _initials,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.blueDark,
                                    ),
                                  ),
                            )
                          : Text(
                              _initials,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.blueDark,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  provider.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (provider.isVerifiedProvider) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.circleCheck,
                          size: 9,
                          color: AppColors.greenDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.verifiedBadge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                _Stat(value: ratingText, label: l10n.ratingLabel),
                const SizedBox(width: 8),
                _Stat(value: '${provider.completedJobs}+', label: l10n.jobsLabel),
                const SizedBox(width: 8),
                _Stat(value: experienceText, label: l10n.experienceLabel),
              ],
            ),
            const SizedBox(height: 12),

            AppCard(
              radius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aboutProvider,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aboutText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),

            AppCard(
              radius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.servicesAndPricing,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  if (result.services.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.noServicesListed,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < result.services.length; i++)
                      _ServiceRow(
                        label: result.services[i].displayLabel,
                        price: result.services[i].displayPrice ?? '—',
                        showDivider: i != result.services.length - 1,
                        onAddToCart: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              serviceId: result.services[i].id,
                            ),
                          ),
                        ),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single "Services & Pricing" row — name/price plus a cart button that
/// opens Review & Schedule for that specific service.
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.label,
    required this.price,
    required this.showDivider,
    required this.onAddToCart,
  });

  final String label;
  final String price;
  final bool showDivider;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFEEF2F5)))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: l10n.addToCart,
            child: Material(
              color: const Color(0xFFE6F7EF),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onAddToCart,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.mintBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.cartPlus,
                    size: 12,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
