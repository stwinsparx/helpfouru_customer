import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'payment_screen.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  // Canonical (non-localized) add-on keys, matched against [AppState]'s
  // add-on tracking. Localize with [_addonLabel] before display.
  static const _addons = <Addon>[
    Addon('AC Foam Cleaning', 299),
    Addon('Copper Pipe Inspection', 149),
    Addon('Cooling Performance Check', 99),
  ];

  static String _addonLabel(AppLocalizations l10n, String key) => switch (key) {
    'AC Foam Cleaning' => l10n.addonAcFoamCleaning,
    'Copper Pipe Inspection' => l10n.addonCopperPipeInspection,
    'Cooling Performance Check' => l10n.addonCoolingPerformanceCheck,
    _ => key,
  };

  static const _slots = [
    '9:00 AM',
    '10:00 AM',
    '11:30 AM',
    '1:00 PM',
    '3:00 PM',
    '5:30 PM',
  ];

  static const _slotEnd = {
    '9:00 AM': '10:00 AM',
    '10:00 AM': '11:00 AM',
    '11:30 AM': '12:30 PM',
    '1:00 PM': '2:00 PM',
    '3:00 PM': '4:00 PM',
    '5:30 PM': '6:30 PM',
  };

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.reviewAndSchedule),

            // Service summary.
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedServiceName(context, state.sub),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.verifiedProDistance,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${state.amount}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            // Add-ons.
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recommendedAddons,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  ..._addons.map((addon) {
                    final added = state.hasAddon(addon.name);
                    final isLast = addon == _addons.last;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(color: Color(0xFFEDF1F4)),
                              ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: AppColors.ink),
                                children: [
                                  TextSpan(
                                    text: _addonLabel(l10n, addon.name),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  ·  ₹${addon.price}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => state.toggleAddon(addon),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: added
                                    ? AppColors.greenDark
                                    : const Color(0xFFE6F7EF),
                                border: Border.all(color: AppColors.mintBorder),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                added ? l10n.added : l10n.add,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: added
                                      ? Colors.white
                                      : AppColors.greenDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Slot picker.
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectBookingSlot,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _slots.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.6,
                        ),
                    itemBuilder: (_, i) {
                      final slot = _slots[i];
                      final selected = state.slot.startsWith(slot);
                      return GestureDetector(
                        onTap: () => state.selectSlot(
                          '$slot - ${_slotEnd[slot] ?? '11:00 AM'}',
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.mint : Colors.white,
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFC5EBD8)
                                  : AppColors.line,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            slot,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selected
                                  ? AppColors.greenDark
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Totals.
            AppCard(
              child: Column(
                children: [
                  DetailRow(label: l10n.serviceLabel, value: '₹${state.amount}'),
                  DetailRow(
                    label: l10n.addonsLabel,
                    value: '₹${state.addonsTotal}',
                    showDivider: false,
                  ),
                  TotalRow(label: l10n.totalLabel, value: '₹${state.subtotal}'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            PrimaryButton(
              label: l10n.proceedToPayment(state.subtotal),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PaymentScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
