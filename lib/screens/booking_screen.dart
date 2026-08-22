import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'payment_screen.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  static const _addons = <Addon>[
    Addon('AC Foam Cleaning', 299),
    Addon('Copper Pipe Inspection', 149),
    Addon('Cooling Performance Check', 99),
  ];

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

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const MiniHeader(title: 'Review & Schedule'),

            // Service summary.
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.sub,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text('Rajesh Kumar · Verified Pro',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text('₹${state.amount}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ),

            // Add-ons.
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recommended Add-ons',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
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
                                bottom: BorderSide(
                                    color: Color(0xFFEDF1F4))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    color: AppColors.ink),
                                children: [
                                  TextSpan(
                                    text: addon.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  TextSpan(
                                    text: '  ·  ₹${addon.price}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => state.toggleAddon(addon),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                color: added
                                    ? AppColors.greenDark
                                    : const Color(0xFFE8F8F1),
                                border: Border.all(
                                    color: AppColors.mintBorder),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                added ? 'ADDED' : 'ADD',
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
                  const Text('Select Booking Slot',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
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
                            '$slot - ${_slotEnd[slot] ?? '11:00 AM'}'),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.mint
                                : Colors.white,
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFBDE8D7)
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
                  DetailRow(label: 'Service', value: '₹${state.amount}'),
                  DetailRow(
                      label: 'Add-ons',
                      value: '₹${state.addonsTotal}',
                      showDivider: false),
                  TotalRow(label: 'Total', value: '₹${state.subtotal}'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            PrimaryButton(
              label: 'Proceed to Payment · ₹${state.subtotal}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaymentScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
