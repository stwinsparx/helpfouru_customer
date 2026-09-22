import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'tracking_screen.dart';

/// Fetches and renders `GET /customer/orders`.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _apiService = ApiService();
  int _tab = 0;
  bool _isLoading = true;
  List<OrderSummary> _orders = const [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/customer/orders');
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final page = OrdersPage.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        setState(() => _orders = page.orders);
      }
    } catch (e) {
      debugPrint('Orders API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OrderSummary> _filteredOrders() => switch (_tab) {
    1 => _orders.where((o) => !o.isFinished).toList(),
    2 => _orders.where((o) => o.status == 'completed').toList(),
    3 => _orders.where((o) => o.status == 'cancelled').toList(),
    _ => _orders,
  };

  void _trackOrder(int orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrackingScreen(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = [
      l10n.orderTabAll,
      l10n.orderTabUpcoming,
      l10n.orderTabCompleted,
      l10n.orderTabCancelled,
    ];
    final orders = _filteredOrders();

    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _fetchOrders,
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

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      l10n.noOrdersFound,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                )
              else
                ...orders.map(
                  (order) => _OrderCard(
                    order: order,
                    onTrack: () => _trackOrder(order.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTrack});

  final OrderSummary order;
  final VoidCallback onTrack;

  (Color, Color) _statusColors() => switch (order.status) {
    'completed' => (const Color(0xFFE7F8F1), AppColors.success),
    'cancelled' => (const Color(0xFFFDE9E9), AppColors.danger),
    _ => (AppColors.mint, AppColors.greenDark),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (statusBg, statusFg) = _statusColors();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
        // Matches the Explore Services category tiles' lifted look on Home.
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A143250),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  order.displayService.isNotEmpty
                      ? order.displayService
                      : '#${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pill(
                label: order.statusLabel,
                background: statusBg,
                foreground: statusFg,
                fontSize: 9.5,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              '#${order.orderNumber}',
              if (order.providerName != null) order.providerName!,
              if (order.bookingSlot != null) order.bookingSlot!,
            ].join(' · '),
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
                order.displayPrice,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!order.isFinished)
                GestureDetector(
                  onTap: onTrack,
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
                      l10n.trackOrder,
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
