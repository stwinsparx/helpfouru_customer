import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

enum NavTab { home, orders, bid, alerts, profile }

/// The 5-slot bottom bar from the prototype's `nav()` helper.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.active, required this.onSelect});
  final NavTab active;
  final ValueChanged<NavTab> onSelect;

  static const _items = <(NavTab, FaIconData, String)>[
    (NavTab.home, FontAwesomeIcons.house, 'Home'),
    (NavTab.orders, FontAwesomeIcons.receipt, 'Orders'),
    (NavTab.bid, FontAwesomeIcons.gavel, 'Bid'),
    (NavTab.alerts, FontAwesomeIcons.bell, 'Alerts'),
    (NavTab.profile, FontAwesomeIcons.user, 'Profile'),
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
                      FaIcon(
                        item.$2,
                        size: 18,
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
