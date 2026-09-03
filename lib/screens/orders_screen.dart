import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);
    final tabs = [
      l10n.orderTabAll,
      l10n.orderTabUpcoming,
      l10n.orderTabCompleted,
      l10n.orderTabCancelled,
    ];

    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.myOrdersTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  tabs.length,
                  (i) => FilterChipButton(
                    label: tabs[i],
                    selected: _tab == i,
                    onTap: () => setState(() => _tab = i),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _OrderCard(
              title: l10n.orderAcServiceTitle,
              status: l10n.orderStatusConfirmed,
              info: l10n.orderAcServiceInfo(
                state.slot,
                localizedServiceName(context, state.sub),
              ),
              amount: '₹${state.payable}',
              actionLabel: l10n.trackOrder,
              onAction: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const TrackingScreen())),
            ),
            _OrderCard(
              title: l10n.orderElectricianTitle,
              status: l10n.orderStatusCompleted,
              statusBg: const Color(0xFFE7F8F1),
              statusFg: AppColors.success,
              info: l10n.orderElectricianInfo,
              amount: '₹699',
              actionLabel: l10n.viewInvoice,
              onAction: () => showAppToast(context, l10n.invoiceOpenedToast),
            ),
            _OrderCard(
              title: l10n.orderCleaningTitle,
              status: l10n.orderStatusCompleted,
              statusBg: const Color(0xFFFEF3E2),
              statusFg: AppColors.warning,
              info: l10n.orderCleaningInfo,
              amount: '₹1,299',
              actionLabel: l10n.rateService,
              onAction: () => showAppToast(context, l10n.reviewScreenOpenedToast),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.title,
    required this.status,
    required this.info,
    required this.amount,
    required this.actionLabel,
    this.onAction,
    this.statusBg = AppColors.mint,
    this.statusFg = AppColors.greenDark,
  });

  final String title;
  final String status;
  final String info;
  final String amount;
  final String actionLabel;
  final VoidCallback? onAction;
  final Color statusBg;
  final Color statusFg;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pill(
                label: status,
                background: statusBg,
                foreground: statusFg,
                fontSize: 9.5,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            info,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7EF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
