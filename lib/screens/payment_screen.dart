import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _method = 0;

  static const _methods = <(String, String)>[
    ('UPI', 'Google Pay · PhonePe · Paytm'),
    ('Debit / Credit Card', 'Visa · Mastercard · RuPay'),
    ('Net Banking', 'All major Indian banks'),
  ];

  void _placeOrder() {
    // Pop back to the shell and land on the Orders tab, then confirm.
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppShell.goToTab(context, 1);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      showAppToast(context, 'Booking confirmed! Order #HFU10284 created.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const MiniHeader(title: 'Secure Payment'),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PAYING FOR',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.sub,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rajesh Kumar · ${state.slot}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  TotalRow(label: 'Payable', value: '₹${state.subtotal}'),
                ],
              ),
            ),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  RadioGroup<int>(
                    groupValue: _method,
                    onChanged: (v) => setState(() => _method = v ?? 0),
                    child: Column(
                      children: List.generate(_methods.length, (i) {
                        final (title, sub) = _methods[i];
                        return GestureDetector(
                          onTap: () => setState(() => _method = i),
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _method == i
                                    ? AppColors.mintBorder
                                    : AppColors.line,
                              ),
                              color: _method == i
                                  ? const Color(0xFFF6FDFA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: i,
                                  activeColor: AppColors.green,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sub,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            AppCard(
              child: Column(
                children: [
                  DetailRow(label: 'Service amount', value: '₹${state.amount}'),
                  DetailRow(label: 'Add-ons', value: '₹${state.addonsTotal}'),
                  const DetailRow(
                    label: 'Platform fee',
                    value: '₹${AppState.platformFee}',
                    showDivider: false,
                  ),
                  TotalRow(label: 'Total', value: '₹${state.payable}'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            PrimaryButton(label: 'Pay & Place Order', onTap: _placeOrder),
            const SizedBox(height: 12),
            const Text(
              '🔒 Secure payment · Refund protection · Invoice generated',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
