import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/provider_card.dart';
import 'provider_profile_screen.dart';
import 'booking_screen.dart';

/// Split layout: sub-service rail on the left, results on the right.
class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  static const _railIcons = <FaIconData>[
    FontAwesomeIcons.snowflake,
    FontAwesomeIcons.screwdriverWrench,
    FontAwesomeIcons.gear,
    FontAwesomeIcons.wandMagicSparkles,
    FontAwesomeIcons.plug,
  ];
  int _filter = 0;

  /// (name, canonical role key, rating, price, distance). The role key is
  /// resolved to a localized label in [build] via [_roleLabel].
  static const _results = <(String, String, String, String, String)>[
    ('Rajesh Kumar', 'AC Repair', '4.9', '₹499', '2.1 km'),
    ('Vikas Meena', 'Home Service Expert', '4.8', '₹449', '2.8 km'),
    ('Deepak Joshi', 'Certified Technician', '4.7', '₹399', '3.4 km'),
    ('Mohit Jain', 'AC & Appliance Pro', '4.9', '₹599', '4.1 km'),
  ];

  String _roleLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    return switch (key) {
      'Home Service Expert' => l10n.roleHomeServiceExpert,
      'Certified Technician' => l10n.roleCertifiedTechnician,
      'AC & Appliance Pro' => l10n.roleAcAppliancePro,
      _ => localizedServiceName(context, key),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final subs = state.subServices;
    final l10n = AppLocalizations.of(context);
    final filters = [
      l10n.filterRecommended,
      l10n.filterNearest,
      l10n.filterTopRated,
      l10n.filterPrice,
    ];

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left rail of sub-services.
            Container(
              width: 88,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppColors.line)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 7,
                ),
                itemCount: subs.length,
                itemBuilder: (_, i) {
                  final key = subs[i];
                  final active = state.sub == key;
                  return GestureDetector(
                    onTap: () => state.selectSub(key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.mint : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          FaIcon(
                            _railIcons[i % _railIcons.length],
                            size: 16,
                            color: active
                                ? AppColors.greenDark
                                : const Color(0xFF68798D),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizedServiceName(context, key),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.5,
                              height: 1.25,
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: active
                                  ? AppColors.greenDark
                                  : const Color(0xFF68798D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Results column.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  MiniHeader(
                    title: localizedServiceName(context, state.category),
                    subtitle: l10n.providersNearbyCount(
                      localizedServiceName(context, state.sub),
                      18,
                    ),
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        filters.length,
                        (i) => FilterChipButton(
                          label: filters[i],
                          selected: _filter == i,
                          onTap: () => setState(() => _filter = i),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._results.map(
                    (r) => ProviderCard(
                      name: r.$1,
                      role: _roleLabel(context, r.$2),
                      rating: r.$3,
                      price: r.$4,
                      distance: r.$5,
                      onViewProfile: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProviderProfileScreen(),
                        ),
                      ),
                      onBook: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BookingScreen(),
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
