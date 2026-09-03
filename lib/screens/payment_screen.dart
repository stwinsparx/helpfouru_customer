import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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

  List<(String, String)> _methods(AppLocalizations l10n) => [
    (l10n.paymentMethodUpi, l10n.paymentMethodUpiSub),
    (l10n.paymentMethodCard, l10n.paymentMethodCardSub),
    (l10n.paymentMethodNetBanking, l10n.paymentMethodNetBankingSub),
  ];

  void _placeOrder() {
    final l10n = AppLocalizations.of(context);
    // Pop back to the shell and land on the Orders tab, then confirm.
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppShell.goToTab(context, 1);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      showAppToast(context, l10n.bookingConfirmedToast);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);
    final methods = _methods(l10n);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.securePayment),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.payingForLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizedServiceName(context, state.sub),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.providerWithSlot(state.slot),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  TotalRow(label: l10n.payableLabel, value: '₹${state.subtotal}'),
                ],
              ),
            ),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.paymentMethod,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  RadioGroup<int>(
                    groupValue: _method,
                    onChanged: (v) => setState(() => _method = v ?? 0),
                    child: Column(
                      children: List.generate(methods.length, (i) {
                        final (title, sub) = methods[i];
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
                                  ? const Color(0xFFF5FCF8)
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
                  DetailRow(label: l10n.serviceAmountLabel, value: '₹${state.amount}'),
                  DetailRow(label: l10n.addonsLabel, value: '₹${state.addonsTotal}'),
                  DetailRow(
                    label: l10n.platformFeeLabel,
                    value: '₹${AppState.platformFee}',
                    showDivider: false,
                  ),
                  TotalRow(label: l10n.totalLabel, value: '₹${state.payable}'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            PrimaryButton(label: l10n.payAndPlaceOrder, onTap: _placeOrder),
            const SizedBox(height: 12),
            Text(
              l10n.securePaymentFooter,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
