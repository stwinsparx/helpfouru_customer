import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

enum NavTab { home, orders, bid, alerts, profile }

/// The 5-slot bottom bar from the prototype's `nav()` helper.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.active, required this.onSelect});
  final NavTab active;
  final ValueChanged<NavTab> onSelect;

  List<(NavTab, FaIconData, String)> _items(AppLocalizations l10n) => [
    (NavTab.home, FontAwesomeIcons.house, l10n.navHome),
    (NavTab.orders, FontAwesomeIcons.receipt, l10n.navOrders),
    (NavTab.bid, FontAwesomeIcons.gavel, l10n.navBid),
    (NavTab.alerts, FontAwesomeIcons.bell, l10n.navAlerts),
    (NavTab.profile, FontAwesomeIcons.user, l10n.navProfile),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _items(AppLocalizations.of(context));
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
            children: items.map((item) {
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
