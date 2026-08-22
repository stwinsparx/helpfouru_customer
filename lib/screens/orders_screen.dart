import 'package:flutter/material.dart';
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
  static const _tabs = ['All', 'Upcoming', 'Completed', 'Cancelled'];
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('My Orders',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _tabs.length,
                  (i) => FilterChipButton(
                    label: _tabs[i],
                    selected: _tab == i,
                    onTap: () => setState(() => _tab = i),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _OrderCard(
              title: 'AC Service · Rajesh Kumar',
              status: 'CONFIRMED',
              info: '#HFU10284 · Today, ${state.slot}\nHome · Udaipur · ${state.sub}',
              amount: '₹${state.payable}',
              actionLabel: 'Track Order',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrackingScreen()),
              ),
            ),
            _OrderCard(
              title: 'Electrician · Amit Sharma',
              status: 'COMPLETED',
              statusBg: AppColors.iceBlue,
              statusFg: AppColors.blue,
              info: '#HFU10121 · 02 Aug 2026\nSwitch & Socket Repair',
              amount: '₹699',
              actionLabel: 'View Invoice',
              onAction: () => showAppToast(context, 'Invoice opened'),
            ),
            _OrderCard(
              title: 'Home Cleaning · Neha Services',
              status: 'COMPLETED',
              statusBg: const Color(0xFFFFF2E2),
              statusFg: const Color(0xFFB66B0A),
              info: '#HFU10087 · 28 Jul 2026\n2BHK Deep Cleaning',
              amount: '₹1,299',
              actionLabel: 'Rate Service',
              onAction: () => showAppToast(context, 'Review screen opened'),
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
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Pill(
                  label: status,
                  background: statusBg,
                  foreground: statusFg,
                  fontSize: 9.5),
            ],
          ),
          const SizedBox(height: 6),
          Text(info,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(amount,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(actionLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
