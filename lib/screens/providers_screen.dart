import 'package:flutter/material.dart';
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
  static const _filters = ['Recommended', 'Nearest', 'Top Rated', 'Price'];
  static const _railEmoji = ['❄', '🛠', '⚙', '✨', '🔌'];
  int _filter = 0;

  static const _results = <(String, String, String, String, String)>[
    ('Rajesh Kumar', 'AC Specialist', '4.9', '₹499', '2.1 km'),
    ('Vikas Meena', 'Home Service Expert', '4.8', '₹449', '2.8 km'),
    ('Deepak Joshi', 'Certified Technician', '4.7', '₹399', '3.4 km'),
    ('Mohit Jain', 'AC & Appliance Pro', '4.9', '₹599', '4.1 km'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final subs = state.subServices;

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
                border:
                    Border(right: BorderSide(color: AppColors.line)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 7),
                itemCount: subs.length,
                itemBuilder: (_, i) {
                  final label = subs[i];
                  final active = state.sub == label;
                  return GestureDetector(
                    onTap: () => state.selectSub(label),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            active ? AppColors.mint : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(_railEmoji[i % _railEmoji.length],
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            label,
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
                    title: state.category,
                    subtitle: '${state.sub} · 18 providers nearby',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        _filters.length,
                        (i) => FilterChipButton(
                          label: _filters[i],
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
                      role: r.$2,
                      rating: r.$3,
                      price: r.$4,
                      distance: r.$5,
                      onViewProfile: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProviderProfileScreen()),
                      ),
                      onBook: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const BookingScreen()),
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
