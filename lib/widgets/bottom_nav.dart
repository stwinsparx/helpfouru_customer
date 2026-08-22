import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NavTab { home, orders, bid, alerts, profile }

/// The 5-slot bottom bar from the prototype's `nav()` helper.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.active, required this.onSelect});
  final NavTab active;
  final ValueChanged<NavTab> onSelect;

  static const _items = <(NavTab, IconData, String)>[
    (NavTab.home, Icons.home_rounded, 'Home'),
    (NavTab.orders, Icons.receipt_long_rounded, 'Orders'),
    (NavTab.bid, Icons.gavel_rounded, 'Bid'),
    (NavTab.alerts, Icons.notifications_rounded, 'Alerts'),
    (NavTab.profile, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: _items.map((item) {
              final selected = item.$1 == active;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelect(item.$1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$2,
                        size: 22,
                        color: selected
                            ? AppColors.greenDark
                            : const Color(0xFF8A97A7),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.greenDark
                              : const Color(0xFF8A97A7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
