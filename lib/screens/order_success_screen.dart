import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// Shown right after a successful `POST /customer/place-order` call.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, this.orderNumber});

  /// The real order number/id from the place-order response, when the API
  /// returned one.
  final String? orderNumber;

  void _backToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  void _viewOrder(BuildContext context) {
    // Pop back to the existing AppShell already in the stack (rather than
    // pushing a new one) so AppShell.goToTab can find it as an ancestor,
    // then land on the Orders tab for this order's history/tracking.
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppShell.goToTab(context, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppGradients.brand,
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.check,
                  size: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.orderPlacedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.orderPlacedBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              AppCard(
                radius: 16,
                child: Column(
                  children: [
                    _SummaryRow(
                      label: l10n.orderNumberLabel,
                      value: orderNumber != null
                          ? '#$orderNumber'
                          : l10n.orderNumberFallback,
                      emphasize: true,
                    ),
                    _SummaryRow(
                      label: l10n.servicesAndPricing,
                      value: localizedServiceName(context, state.sub),
                    ),
                    _SummaryRow(
                      label: l10n.scheduledForLabel,
                      value: state.slot,
                    ),
                    _SummaryRow(
                      label: l10n.amountPaidLabel,
                      value: '₹${state.payable}',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.viewOrderInHistory,
                onTap: () => _viewOrder(context),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: l10n.backToHome,
                onTap: () => _backToHome(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFEEF2F5)))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: emphasize ? 14 : 12,
                fontWeight: FontWeight.w800,
                color: emphasize ? AppColors.greenDark : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
