import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/saved_addresses_screen.dart';
import 'common.dart';

/// Shows the Blinkit-style location picker as a bottom sheet from the home
/// screen's address block — "Use current location" (the live GPS address)
/// pinned at the top, every saved address below it, and "Add new address"
/// at the bottom.
///
/// Unlike the mandatory pickers in `service_selection_sheets.dart`, this one
/// is purely optional and selects immediately on tap (no "Continue" gate) —
/// dismissing it without picking anything (X, tap-outside, back) just keeps
/// whatever was already selected, so there's nothing for the caller to
/// react to; the result isn't awaited for a value.
///
/// NOTE: addresses are fully local/mock — see [SavedAddress] — so "Add new
/// address" closes this sheet and opens `SavedAddressesScreen`, which itself
/// still only surfaces a toast rather than actually creating one.
void showLocationPickerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xCC12243B),
    builder: (context) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends StatelessWidget {
  const _LocationPickerSheet();

  static String _labelFor(AppLocalizations l10n, String key) => switch (key) {
    'Home' => l10n.addressTypeHome,
    'Office' => l10n.addressTypeOffice,
    _ => l10n.addressTypeOther,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppStateScope.of(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8EF),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.selectDeliveryLocationTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  _LocationRow(
                    icon: FontAwesomeIcons.locationCrosshairs,
                    iconColor: AppColors.blue,
                    iconBackground: AppColors.iceBlue,
                    title: l10n.useCurrentLocation,
                    subtitle: l10n.useCurrentLocationHint,
                    selected: state.selectedAddress == null,
                    onTap: () {
                      state.selectAddress(null);
                      Navigator.of(context).pop();
                    },
                  ),
                  if (state.addresses.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: Color(0xFFEEF2F5)),
                    ),
                    for (final address in state.addresses)
                      _LocationRow(
                        icon: address.icon,
                        iconColor: AppColors.greenDark,
                        iconBackground: AppColors.mint,
                        title: _labelFor(l10n, address.label),
                        subtitle: address.line.replaceAll('\n', ' '),
                        selected: state.selectedAddress == address,
                        onTap: () {
                          state.selectAddress(address);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFFEEF2F5)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SecondaryButton(
                label: l10n.addNewAddress,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SavedAddressesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final FaIconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5FCF8) : Colors.white,
            border: Border.all(
              color: selected ? AppColors.mintBorder : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: selected ? AppColors.greenDark : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? AppColors.green : const Color(0xFFA3AFBD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
