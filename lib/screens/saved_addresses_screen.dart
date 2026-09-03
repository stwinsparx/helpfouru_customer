import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class _Address {
  _Address({
    required this.icon,
    required this.label,
    required this.line,
    required this.contact,
    this.isDefault = false,
  });

  final FaIconData icon;

  /// Canonical (non-localized) address label key — `'Home'` or `'Office'`.
  /// Localize with [AppLocalizations.addressTypeHome] / `.addressTypeOffice`
  /// via [_SavedAddressesScreenState._labelFor] before display.
  final String label;
  final String line;
  final String contact;
  bool isDefault;
}

/// Address book reached from Profile → Saved Addresses.
class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _addresses = [
    _Address(
      icon: FontAwesomeIcons.house,
      label: 'Home',
      line:
          '12 Lake View Road, Hiran Magri Sector 4,\nUdaipur, Rajasthan 313001',
      contact: 'Shubham Kumar · 98765 43210',
      isDefault: true,
    ),
    _Address(
      icon: FontAwesomeIcons.briefcase,
      label: 'Office',
      line: '3rd Floor, Tech Park, Madhuban,\nUdaipur, Rajasthan 313002',
      contact: 'Shubham Kumar · 98765 43210',
    ),
  ];

  static String _labelFor(AppLocalizations l10n, String key) => switch (key) {
    'Home' => l10n.addressTypeHome,
    'Office' => l10n.addressTypeOffice,
    _ => l10n.addressTypeOther,
  };

  void _makeDefault(int index) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i].isDefault = i == index;
      }
    });
    showAppToast(context, l10n.setAsDefaultToast(_labelFor(l10n, _addresses[index].label)));
  }

  void _confirmDelete(int index) {
    final l10n = AppLocalizations.of(context);
    final address = _addresses[index];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteAddressQuestion,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.deleteAddressConfirmBody(_labelFor(l10n, address.label)),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() => _addresses.removeAt(index));
              showAppToast(context, l10n.addressDeletedToast);
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            MiniHeader(
              title: l10n.savedAddressesHeader,
              subtitle: l10n.savedCount(_addresses.length),
            ),

            if (_addresses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Column(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.mapLocationDot,
                      size: 34,
                      color: Color(0xFFB6C2CF),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.noSavedAddresses,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.addAddressFasterBooking,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_addresses.length, (i) {
                final a = _addresses[i];
                return AppCard(
                  radius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: FaIcon(
                              a.icon,
                              size: 14,
                              color: AppColors.greenDark,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _labelFor(l10n, a.label),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    if (a.isDefault) ...[
                                      const SizedBox(width: 7),
                                      Pill(
                                        label: l10n.defaultBadge,
                                        fontSize: 8.5,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  a.line,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  a.contact,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9AA7B6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          _AddressAction(
                            icon: FontAwesomeIcons.penToSquare,
                            label: l10n.editLabel,
                            onTap: () => showAppToast(
                              context,
                              l10n.editAddressToast(_labelFor(l10n, a.label)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _AddressAction(
                            icon: FontAwesomeIcons.trashCan,
                            label: l10n.deleteLabel,
                            danger: true,
                            onTap: () => _confirmDelete(i),
                          ),
                        ],
                      ),
                      // Offered only on non-default addresses; kept on its
                      // own row so the labels never squeeze.
                      if (!a.isDefault) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _AddressAction(
                              icon: FontAwesomeIcons.circleCheck,
                              label: l10n.setAsDefault,
                              onTap: () => _makeDefault(i),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),

            const SizedBox(height: 6),
            SecondaryButton(
              label: l10n.addNewAddress,
              onTap: () => showAppToast(context, l10n.addAddressFormOpenedToast),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressAction extends StatelessWidget {
  const _AddressAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colour = danger ? AppColors.danger : AppColors.blue;
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, size: 11, color: colour),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colour,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
